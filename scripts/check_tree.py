#!/usr/bin/env python3
import os
import subprocess
import json
from pathlib import Path

REPO_ROOT = Path(__file__).parent.parent
HOSTS_DIR = REPO_ROOT / "hosts"
MODULES_DIR = REPO_ROOT / "modules"

def run_nix(args):
    try:
        res = subprocess.run(
            ["nix"] + args,
            capture_output=True,
            text=True,
            check=True,
            cwd=REPO_ROOT
        )
        return True, res.stdout, res.stderr
    except subprocess.CalledProcessError as e:
        return False, e.stdout, e.stderr 
        
def get_hosts():
    ok, out, _ = run_nix(["flake", "show", "--json"])
    if not ok: return []
    data = json.loads(out)
    return list(data.get("nixosConfigurations",{}).keys())

def check_host(host):
    ok, _, err = run_nix(["eval", f".#nixosConfigurations.{host}.config.system.build.toplevel.drvPath"])
    if not ok:
        lines = [l for l in (err or "").splitlines() if l.strip()]
        short = "\n".join(lines[-3:]) if lines else "Unknown error"
        return {"status":False, "error":short, "options":{}}
    ok, out, _ = run_nix(["eval", f".#nixosConfigurations.{host}.options", "--json"])
    options = json.loads(out) if ok else {}
    return {"status":True, "error":None, "options":options}

def flatten_options(opts, prefix=""):
    flat = []
    for k, v in opts.items():
        path = f"{prefix}.{k}" if prefix else k
        if isinstance(v, dict):
            if v.get("_type") == "option":
                decls = v.get("declarations", [])
                opt_type = v.get("type", {}).get("name", "any")
                flat.append((path, opt_type, decls))
            else:
                flat.extend(flatten_options(v, path))
    return flat

def get_host_module_files(host):
    ok, out, _ = run_nix([
        "eval", f".#nixosConfigurations.{host}.config._moduleFiles", "--json"
    ])
    if not ok:
        return set()
    data = json.loads(out) if out else []
    if not isinstance(data, list):
        return set()
    result = set()
    for p in map(str, data):
        rel = p.split("/source/")[-1] if "/source/" in p else p
        result.add(rel)
    return result

def get_host_module_names(host):
    ok, out, _ = run_nix([
        "eval",
        f".#nixosConfigurations.{host}.config._moduleNames",
        "--json"
    ])
    if not ok:
        return set()
    try:
        data = json.loads(out)
    except json.JSONDecodeError:
        return set()
    if isinstance(data, list):
        return set(map(str, data))
    if isinstance(data, str):
        return {data}
    return set()

def map_options_to_files(flat_options):
    file_map = {}
    for opt_path, opt_type, decls in flat_options:
        for decl in decls:
            # find suffix because Nix stores stuff in /nix/store/...-source/...
            rel_decl = decl.split("/source/")[-1] if "/source/" in decl else decl
            local_path = REPO_ROOT / rel_decl
            if local_path.exists():
                rel_str = str(local_path.relative_to(REPO_ROOT))
                if rel_str not in file_map:
                    file_map[rel_str] = []
                file_map[rel_str].append(f"{opt_path} ({opt_type})")
    return file_map

def is_module_used(mod_rel: str, used_names: set) -> bool:
    """mod_rel — путь относительно modules/, например 'desktopEnv'
    или 'desktopEnv/kde'. Считаем модуль используемым, если:
      - его путь точно есть в used_names, или
      - какой-то used_name начинается с mod_rel + '/' (вложенный модуль),
      - или mod_rel начинается с used_name + '/' (родитель используемого).
    """
    if not used_names:
        return True
    for name in used_names:
        if name == mod_rel:
            return True
        if name.startswith(mod_rel + "/"):
            return True
        if mod_rel.startswith(name + "/"):
            return True
    return False

def print_tree():
    hosts = get_hosts()
    print(f"📂 {REPO_ROOT.name}")
    errors = {}  # host -> short error
    
    local_files = {}
    for d in [HOSTS_DIR, MODULES_DIR]:
        if d.exists():
            for root, _, files in os.walk(d):
                for f in files:
                    if f.endswith(".nix"):
                        rel = str(Path(root, f).relative_to(REPO_ROOT))
                        local_files.setdefault(Path(rel).parent, []).append(f)
    for host in hosts:
        print(f"├── 🖥️  host: {host}")
        host_data = check_host(host)
        status = host_data["status"]
        if status == False:
            errors[host] = host_data["error"]
        file_map = map_options_to_files(flatten_options(host_data["options"])) if status else {}
        
        used_module_names = get_host_module_names(host) if status else set()
        
        host_dir = Path(f"hosts/{host}")
        if host_dir in local_files:
            for f in local_files[host_dir]:
                f_path = f"{host_dir}/{f}"
                host_files = get_host_module_files(host) if status else set()
                if status == False:
                    f_status = "❌"
                elif host_files:
                    
                    f_status = "✔" if f_path in host_files else "⚪"
                else:
                    f_status = "✔" if f_path in file_map else "⚪"
                
                print(f"│   ├── 📄 {f} {f_status}")
                if f_path in file_map:
                    for opt in file_map[f_path][:3]: # Get first 3
                        print(f"│   │   └── ⚙️  {opt}")
                    if len(file_map[f_path]) > 3:
                        print(f"│   │   └── ... and {len(file_map[f_path]) - 3} more options")

        print(f"│   └── 📂 modules (used in {host})")
        def walk_modules(base: Path, prefix: str = ""):
            if not base.exists():
                return
            for entry in sorted(base.iterdir()):
                if not entry.is_dir():
                    continue
                rel = f"{prefix}/{entry.name}" if prefix else entry.name
                yield rel, entry
                yield from walk_modules(entry, rel)

        for rel, mod_dir in walk_modules(MODULES_DIR):
            if not is_module_used(rel, used_module_names):
                continue
            depth = rel.count("/")
            indent = "│       " + "    " * depth
            mod_status = "❌" if status == False else "✔"
            print(f"{indent}├── 📂 {rel} {mod_status}")
    if errors:
        print("\n" + "=" * 60)
        print("⚠️  Eval Errors:")
        print("=" * 60)
        for host, err in errors.items():
            print(f"\n🖥️  {host}:")
            for line in err.splitlines():
                print(f"    {line}")
    else:
        print("\n✅ Everything was evaluated.")
if __name__ == "__main__":
    print("Start repo checkup and tree building...\n")
    print_tree()
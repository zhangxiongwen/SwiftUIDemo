#!/usr/bin/env python3
import os
import sys

def replace_in_file(file_path, old_str, new_str):
    try:
        # 读取文件内容，尝试 UTF-8
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        if old_str in content:
            new_content = content.replace(old_str, new_str)
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(new_content)
            return True
    except UnicodeDecodeError:
        # 如果是二进制文件（如 Assets），跳过
        pass
    except Exception as e:
        print(f"Error processing file {file_path}: {e}")
    return False

def rename_project(old_name, new_name):
    # 1. 获取脚本所在目录
    root_dir = os.getcwd()
    print(f"🚀 Starting rename from '{old_name}' to '{new_name}' in {root_dir}...")

    # 2. 遍历所有文件，替换文件内容 (Content Replacement)
    print("📝 Updating file contents...")
    for dirpath, dirnames, filenames in os.walk(root_dir):
        # 忽略 .git 目录
        if ".git" in dirpath:
            continue
            
        for filename in filenames:
            # 忽略脚本自己和 .DS_Store
            if filename == "rename_project.py" or filename == ".DS_Store":
                continue
                
            file_path = os.path.join(dirpath, filename)
            replace_in_file(file_path, old_name, new_name)

    # 3. 重命名文件夹和文件 (Filesystem Renaming)
    # 注意：需要自底向上遍历 (bottom-up)，否则重命名父文件夹后子文件夹路径会失效
    print("Example: Renaming directories and files...")
    for dirpath, dirnames, filenames in os.walk(root_dir, topdown=False):
        if ".git" in dirpath:
            continue
            
        # 重命名文件
        for filename in filenames:
            if old_name in filename:
                old_file_path = os.path.join(dirpath, filename)
                new_filename = filename.replace(old_name, new_name)
                new_file_path = os.path.join(dirpath, new_filename)
                os.rename(old_file_path, new_file_path)

        # 重命名文件夹
        for dirname in dirnames:
            if old_name in dirname:
                old_dir_path = os.path.join(dirpath, dirname)
                new_dirname = dirname.replace(old_name, new_name)
                new_dir_path = os.path.join(dirpath, new_dirname)
                os.rename(old_dir_path, new_dir_path)

    print(f"✅ Project renamed to {new_name} successfully!")
    print("⚠️  Make sure to run 'Pod install' if you use CocoaPods, or wait for SPM to resolve.")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 rename_project.py <OldName> <NewName>")
        print("Example: python3 rename_project.py IOSAppTemplate SuperShop")
    else:
        old_name = sys.argv[1]
        new_name = sys.argv[2]
        rename_project(old_name, new_name)

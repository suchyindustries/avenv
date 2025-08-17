# avenv - Advanced Virtual Environment Management

> **Effortlessly manage Python virtual environments with intelligent auto-discovery**

`avenv` is a robust bash function that automatically finds and activates the nearest Python virtual environment in your project hierarchy. No more manual navigation or remembering complex paths - just type `avenv` and get to work.

## ✨ Key Features

- **🔍 Smart Discovery**: Automatically searches upward through directories to find virtual environments
- **⚡ Instant Activation**: One command to find and activate your project's venv
- **🛠️ Environment Management**: Create, fix, and manage virtual environments seamlessly  
- **🔧 Auto-Repair**: Intelligent fixing of broken or moved virtual environments
- **📁 Flexible Naming**: Support for custom venv names and locations
- **🛡️ Error Handling**: Graceful handling of missing dependencies and edge cases

## 🚀 Installation

### Prerequisites

- **Linux Mint** (tested and verified)
- **Bash shell** 
- **Python 3.6+** with `venv` module
- **Standard Unix utilities** (dirname, mktemp, grep, etc.)

### Quick Installation

1. **Download the avenv function**:
   ```bash
   curl -o ~/.avenv.bash https://raw.githubusercontent.com/suchyindustries/avenv/main/avenv.bash
   ```

2. **Add to your shell profile**:
   ```bash
   # For bash users
   echo "source ~/.avenv.bash" >> ~/.bashrc
   
   # For zsh users (if using zsh on Linux Mint)
   echo "source ~/.avenv.bash" >> ~/.zshrc
   ```

3. **Reload your shell**:
   ```bash
   source ~/.bashrc  # or source ~/.zshrc if using zsh
   ```

### Manual Installation

Copy the `avenv()` function from `avenv.bash` and paste it into your `~/.bashrc` or `~/.zshrc` file, then reload your shell.

## 📖 Usage

### Basic Commands

| Command | Description |
|---------|-------------|
| `avenv` | Find and activate nearest virtual environment |
| `avenv new [name]` | Create new virtual environment (default: `.venv`) |
| `avenv fix` | Repair broken/moved virtual environment |
| `avenv deactivate` | Deactivate current virtual environment |
| `avenv help` | Display help message |

### Common Workflows

#### 🔄 Activate Existing Environment
```bash
cd /path/to/your/project
avenv
# → Automatically finds and activates .venv, venv, or any other venv in project hierarchy
```

#### 🆕 Create New Environment
```bash
# Create default .venv
avenv new

# Create custom named environment
avenv new myproject-env
```

#### 🛠️ Fix Broken Environment
```bash
avenv fix
# → Analyzes environment, freezes packages, offers to recreate with same packages
```

## 💡 Examples

### Project Structure Example
```
my-project/
├── .venv/              # ← avenv will find this
│   └── bin/activate
├── src/
│   └── myapp/
├── tests/              # ← Running 'avenv' from here works
└── docs/               # ← Running 'avenv' from here works too
```

### Interactive Repair Session
```bash
$ avenv fix
Found virtual environment at: /home/user/project/.venv
Warning: The venv seems to have been moved.
  Expected creation command: /usr/bin/python3 -m venv /home/user/project/.venv
  Actual creation command: /usr/bin/python3 -m venv /old/path/project/.venv
Freezing installed packages...
Found the following packages:
requests==2.28.1
numpy==1.24.0
pandas==1.5.2

Reinstall these packages to fix the environment? (y/N) y
Fixing environment by recreating it and reinstalling packages...
Environment fixed successfully.
```

## 🏗️ How It Works

1. **Directory Traversal**: Starting from current directory, searches upward through parent directories
2. **Environment Detection**: Looks for any directory containing `bin/activate` file
3. **Smart Activation**: Activates the first valid virtual environment found
4. **Fallback Guidance**: Provides clear instructions if no environment is found

## ⚙️ Advanced Configuration

### Environment Detection Logic
`avenv` detects virtual environments by looking for the `bin/activate` script. It will find:
- `.venv/` (most common)
- `venv/`
- `env/` 
- Any custom-named directory with proper venv structure

### Customization Options
The function can be modified to:
- Skip certain directory patterns
- Prefer specific environment names
- Add custom validation logic
- Include additional setup commands

## 🐛 Troubleshooting

### Common Issues

**"python3 command not found"**
- Install Python 3: `sudo apt install python3` (Linux Mint/Ubuntu/Debian)

**"No virtual environment found"**
- Create one: `avenv new`
- Check if you're in the right project directory

**Environment activation fails**
- Try fixing: `avenv fix`
- Manually recreate if needed: `rm -rf .venv && avenv new`

**Permission errors**
- Ensure you have write permissions in the project directory
- Check that Python has permission to create files

## 🤝 Contributing

We welcome contributions! Here's how you can help:

1. **🐛 Bug Reports**: Open an issue with detailed reproduction steps
2. **💡 Feature Requests**: Describe your use case and proposed solution  
3. **🔧 Code Contributions**: Fork, create feature branch, submit PR
4. **📚 Documentation**: Improve examples, fix typos, add use cases

### Development Setup
```bash
git clone https://github.com/suchyindustries/avenv.git
cd avenv
# Test the function in a new shell session
bash -c "source avenv.bash && avenv help"
```

## 📋 Requirements

- **OS**: Linux Mint (tested and verified)
- **Shell**: Bash 4.0+ or Zsh 5.0+
- **Python**: 3.6+ with venv module
- **Tools**: Standard POSIX utilities

## 📄 License

This project is licensed under the **MIT License** - see below for details:

```
MIT License

Copyright (c) 2024 Suchy Industries

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
---

**Made with ❤️ by [Suchy Industries](https://github.com/suchyindustries) and AI's**

*Simplifying Python development workflows, one environment at a time.*

## avenv: Lazy Programmer's Delight for Virtual Environments

**Tired of manually activating your virtual environments?**  avenv makes your life easier by automatically finding and activating the nearest `.venv` folder for you. 

**Features:**

* **Simple:**  Just run `avenv` and it does the rest.
* **Automatic:**  Automatically searches up the directory tree for your `.venv`.
* **Cross-Platform:**  Works on both Linux/macOS and Windows.

**How it works:**

avenv is a shell function that:

1. **Starts at your current directory.**
2. **Looks for a `.venv` folder.**
3. **If found, activates the virtual environment.**
4. **If not found, it moves up one directory and repeats.**
5. **If it reaches the root directory without finding `.venv`, it informs you.**

**Installation:**

1. **Copy the appropriate script:** 
   * **Linux/macOS:**  Copy the `bashrc` content to the end of your `.bashrc` file. (accessible by running `nano ~/.bashrc` in PowerShell).
   * **Windows:**  Copy the `$profile` content to your PowerShell profile file (accessible by running `notepad $profile` in PowerShell).

2. **Source your profile:**
   * **Linux/macOS:**  Run `source ~/.bashrc`.
   * **Windows:**  Close and reopen PowerShell.

**Usage:**

1. **Navigate to your project directory.**
2. **Run `avenv` in your terminal.**

**Example:**

Let's say you have a project structure like this:

```
project_folder/
├── .venv/
│   └── bin/
│       ├── activate
│       └── ... 
├── src/
│   ├── ...
└── tests/
    ├── ...
```

If you're in the `tests` directory and run `avenv`, it will automatically find and activate the `.venv` in the `project_folder` directory. 

**Enjoy your newfound laziness!** 

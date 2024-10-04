## avenv: Advanced Virtual Environment Management Tool

**Effortlessly manage your Python virtual environments** with `avenv`, a powerful utility designed to locate and activate the nearest virtual environment, simplifying your workflow and boosting productivity.

### Key Features:

* **Streamlined Activation:** Run `avenv` and let it handle the rest, no manual activation required.
* **Automatic Environment Detection:** Seamlessly searches up the directory tree for any folder with a typical virtual environment structure and activates it.
* **Flexible Environment Creation:** Quickly create a new virtual environment with `avenv new [name]`—fully customizable to suit your project needs.
* **Cross-Platform Compatibility:** Fully operational on both Linux/macOS and Windows, ensuring seamless usage across environments.

### How It Works:

`avenv` is a shell function that:

1. **Initiates at the Current Directory**: It begins searching from your current location.
2. **Searches for a Virtual Environment**: Scans for folders that contain the typical virtual environment structure (`bin/activate` or `Scripts/Activate.ps1`).
3. **Activates if Found**: Activates the virtual environment once located.
4. **Continues Searching if Not Found**: Moves up to the parent directory and repeats until the root directory is reached.
5. **Provides Feedback**: If no virtual environment is found, informs the user accordingly.

### Installation Instructions:

1. **Add the Function to Your Terminal Profile:**
   
   * **Linux/macOS:** Copy the `bashrc` script to the end of your `.bashrc` or `.zshrc` file (e.g., run `nano ~/.bashrc` in your terminal).
   * **Windows:** Add the script to your PowerShell profile file (`notepad $profile` in PowerShell).

   ```sh
   # Add the following to your terminal profile (Linux/macOS)
   function avenv {
       # Implementation here
   }
   ```

   ```powershell
   # Windows PowerShell implementation
   function avenv {
       # Implementation here
   }
   ```

2. **Apply Changes to Your Profile:**
   * **Linux/macOS:** Execute `source ~/.bashrc` or `source ~/.zshrc` to apply the changes.
   * **Windows:** Close and reopen PowerShell to apply the modifications.

### Usage Guide:

1. **Navigate to Your Project Directory:** Use `cd` to move to your project directory.
2. **Activate the Environment:** Run `avenv` in your terminal. `avenv` will automatically find and activate the nearest virtual environment.

### Creating a New Virtual Environment:

* **Default Environment Creation:** Run `avenv new` to create a new virtual environment named `.venv` in the current directory.
* **Custom Environment Creation:** Specify a custom name with `avenv new [name]`.

### Example:

Imagine the following project structure:

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

If you are located in the `tests` directory and execute `avenv`, the tool will identify and activate the `.venv` located in the `project_folder` directory.

### Embrace Effortless Virtual Environment Management

`avenv` empowers developers by streamlining the activation and management of virtual environments, enabling you to focus on what matters most—building amazing software.

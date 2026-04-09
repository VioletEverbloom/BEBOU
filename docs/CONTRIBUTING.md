# Requirements

- [Visual Studio Code](https://code.visualstudio.com/download)
- [Git](https://git-scm.com/install/)
- [Prism Launcher](https://prismlauncher.org/download/windows/)

# How to setup a development instance

1. In Prism Launcher, select `Add Instance`. In the `Custom` Tab, select the version `26.1` and `Fabric` as a Mod Loader.
2. Select your instance and click on the `Folder` button.
3. Open your terminal in the file explorer that opened, and run :

    ``` bash
    git clone https://github.com/VioletEverbloom/BEBOU.git minecraft
    ```

4. Download [Pakku's latest release](https://github.com/juraj-hrivnak/Pakku/releases) and place the jar in the `minecraft` folder.
5. Open VSCode in the `minecraft` folder.
6. Run the task (`CTRL+Shift+B`) `Copy Prism Pre-launch Command to clipboard`. Then, in Prism Launcher, select your instance, click the `Edit` button, go to `Settings > Custom Commands`, check `Override Global Settings` and paste the command inside the `Pre-launch Command` text field.

That's it! The instance is ready to be edited!

# Editing the instance

Using build tasks (`CTRL+Shift+B`), you can easily modify the instance. Here is a brief overview of the most important tasks. See [Definitions](#definitions) for more informations on technical terms.

- `Add project`: Adds one (or multiple) project(s) to the instance.
- `Remove project`: Removes one (or multiple) project(s) from the instance.
- `Set project to client side`: Sets a project to be only exported on a client instance.
- `Set project to server side`: Sets a project to be only exported on a server instance.
- `List installed projects`: List information about all of the current projects.
- `Get the projects' status`: Checks which projects can be updated.
- `Update installed projects`: Update all projects (with `-a`) or only selected projects (with their Modrinth slugs).
- `Run Pakku`: General command. Refer to the official [Pakku Docs](https://juraj-hrivnak.github.io/Pakku/home.html) for more information.

# Definitions

- `Project`: A general term for anything that can be added to a modpack, this includes Mods, Resource Packs, Data Packs, Shaders and Worlds
- `Modrinth slug`: A unique identifier for a project used by Pakku. To get the slug of a mod, look at the URL of its main page. For instance, `https://modrinth.com/mod/sodium` means that Sodium's slug is `sodium`

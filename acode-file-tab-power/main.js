(function () {
  const pluginId = "acode.filetab.power";

  const toast = (msg, duration = 3000) => {
    if (window.acode?.toast) return window.acode.toast(msg, duration);
    if (window.toast) return window.toast(msg, duration);
    console.log(`[${pluginId}] ${msg}`);
  };

  const getFs = () => {
    if (window.acode?.require) {
      try {
        return window.acode.require("fsOperation");
      } catch (err) {
        console.error(err);
      }
    }
    return null;
  };

  const ask = async (label, placeholder = "") => {
    const value = prompt(label, placeholder);
    if (value === null) return null;
    return String(value).trim();
  };

  const withCurrentDir = async (handler) => {
    const fs = getFs();
    if (!fs) {
      toast("Não foi possível acessar fsOperation no Acode.");
      return;
    }

    const currentDir =
      window.editorManager?.activeFile?.uri?.replace(/\/[^/]*$/, "") ||
      window.editorManager?.activeFile?.location ||
      "/sdcard";

    try {
      await handler(fs, currentDir);
      window.fileBrowser?.reload?.();
    } catch (error) {
      console.error(error);
      toast(`Erro: ${error.message || error}`);
    }
  };

  const actions = [
    {
      id: `${pluginId}:newFile`,
      label: "File Tab Power: Novo arquivo",
      run: () =>
        withCurrentDir(async (fs, baseDir) => {
          const name = await ask("Nome do arquivo", "novo_arquivo.txt");
          if (!name) return;
          if (fs.createFile) {
            await fs.createFile(baseDir, name, "");
            toast(`Arquivo criado: ${name}`);
            return;
          }
          throw new Error("Método createFile não disponível no fsOperation.");
        }),
    },
    {
      id: `${pluginId}:newFolder`,
      label: "File Tab Power: Nova pasta",
      run: () =>
        withCurrentDir(async (fs, baseDir) => {
          const name = await ask("Nome da pasta", "nova_pasta");
          if (!name) return;
          if (fs.createDirectory) {
            await fs.createDirectory(`${baseDir}/${name}`);
            toast(`Pasta criada: ${name}`);
            return;
          }
          if (fs.mkdir) {
            await fs.mkdir(`${baseDir}/${name}`);
            toast(`Pasta criada: ${name}`);
            return;
          }
          throw new Error("Método para criar pasta não disponível no fsOperation.");
        }),
    },
    {
      id: `${pluginId}:rename`,
      label: "File Tab Power: Renomear item",
      run: () =>
        withCurrentDir(async (fs, baseDir) => {
          const oldPath = await ask("Caminho atual", `${baseDir}/arquivo.txt`);
          if (!oldPath) return;
          const newName = await ask("Novo nome", "arquivo_renomeado.txt");
          if (!newName) return;

          if (fs.renameTo) {
            await fs.renameTo(oldPath, newName);
            toast("Item renomeado com sucesso.");
            return;
          }
          if (fs.rename) {
            await fs.rename(oldPath, newName);
            toast("Item renomeado com sucesso.");
            return;
          }
          throw new Error("Método de renomear não disponível no fsOperation.");
        }),
    },
    {
      id: `${pluginId}:copy`,
      label: "File Tab Power: Copiar item",
      run: () =>
        withCurrentDir(async (fs, baseDir) => {
          const source = await ask("Origem", `${baseDir}/arquivo.txt`);
          if (!source) return;
          const destination = await ask("Destino", `${baseDir}/copia_arquivo.txt`);
          if (!destination) return;

          if (fs.copy) {
            await fs.copy(source, destination);
            toast("Item copiado com sucesso.");
            return;
          }
          throw new Error("Método copy não disponível no fsOperation.");
        }),
    },
    {
      id: `${pluginId}:move`,
      label: "File Tab Power: Mover item",
      run: () =>
        withCurrentDir(async (fs, baseDir) => {
          const source = await ask("Origem", `${baseDir}/arquivo.txt`);
          if (!source) return;
          const destination = await ask("Destino", `${baseDir}/movido_arquivo.txt`);
          if (!destination) return;

          if (fs.move) {
            await fs.move(source, destination);
            toast("Item movido com sucesso.");
            return;
          }
          if (fs.copy && fs.delete) {
            await fs.copy(source, destination);
            await fs.delete(source);
            toast("Item movido (copy+delete) com sucesso.");
            return;
          }
          throw new Error("Método move não disponível no fsOperation.");
        }),
    },
    {
      id: `${pluginId}:delete`,
      label: "File Tab Power: Excluir item",
      run: () =>
        withCurrentDir(async (fs, baseDir) => {
          const target = await ask("Caminho para excluir", `${baseDir}/arquivo.txt`);
          if (!target) return;
          const ok = confirm(`Confirmar exclusão?\n${target}`);
          if (!ok) return;

          if (fs.delete) {
            await fs.delete(target);
            toast("Item excluído.");
            return;
          }
          if (fs.unlink) {
            await fs.unlink(target);
            toast("Item excluído.");
            return;
          }
          throw new Error("Método delete não disponível no fsOperation.");
        }),
    },
  ];

  const registerCommand = (action) => {
    if (window.acode?.registerCommand) {
      window.acode.registerCommand(action.id, action.label, action.run);
      return true;
    }

    if (window.editorManager?.editor?.commands?.addCommand) {
      window.editorManager.editor.commands.addCommand({
        name: action.id,
        bindKey: { win: null, mac: null },
        exec: action.run,
      });
      return true;
    }

    return false;
  };

  const unregisterCommand = (action) => {
    if (window.acode?.unregisterCommand) {
      window.acode.unregisterCommand(action.id);
      return;
    }

    if (window.editorManager?.editor?.commands?.removeCommand) {
      window.editorManager.editor.commands.removeCommand(action.id);
    }
  };

  const init = () => {
    const registered = actions.map(registerCommand);
    const total = registered.filter(Boolean).length;
    if (!total) {
      toast("File Tab Power carregado, mas sem API de comandos disponível.");
      return;
    }
    toast(`File Tab Power ativo (${total} comandos).`);
  };

  const destroy = () => {
    actions.forEach(unregisterCommand);
    toast("File Tab Power desativado.");
  };

  if (window.acode?.setPluginInit && window.acode?.setPluginUnmount) {
    window.acode.setPluginInit(pluginId, init);
    window.acode.setPluginUnmount(pluginId, destroy);
  } else {
    init();
  }
})();

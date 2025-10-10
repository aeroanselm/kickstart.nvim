-- lua/user/lsp/julials.lua

local M = {}

-- Funzione per trovare la root del progetto
local function find_root(patterns)
  local path = vim.fn.expand '%:p:h'
  while path ~= '/' do
    for _, pattern in ipairs(patterns) do
      if vim.fn.glob(path .. '/' .. pattern) ~= '' then
        return path
      end
    end
    path = vim.fn.fnamemodify(path, ':h')
  end
  return vim.loop.cwd()
end

-- Funzione per attivare un ambiente Julia
local function activate_env(path)
  if not path or path == '' then
    vim.notify("⚠️  Specifica un percorso valido per l'ambiente Julia.", vim.log.levels.WARN)
    return
  end
  vim.env.JULIA_PROJECT = path
  vim.notify('✅ Ambiente Julia attivato: ' .. path, vim.log.levels.INFO)
end

M.config = {
  cmd = {
    'julia',
    '--startup-file=no',
    '--history-file=no',
    '-e',
    [[
      ls_install_path = joinpath(
          get(DEPOT_PATH, 1, joinpath(homedir(), ".julia")),
          "environments", "nvim-lspconfig"
      )
      pushfirst!(LOAD_PATH, ls_install_path)
      using LanguageServer
      popfirst!(LOAD_PATH)
      depot_path = get(ENV, "JULIA_DEPOT_PATH", "")
      project_path = let
          dirname(something(
              Base.load_path_expand((
                  p = get(ENV, "JULIA_PROJECT", nothing);
                  p === nothing ? nothing : isempty(p) ? nothing : p
              )),
              Base.current_project(),
              get(Base.load_path(), 1, nothing),
              Base.load_path_expand("@v#.#"),
          ))
      end
      @info "Running language server" VERSION pwd() project_path depot_path
      server = LanguageServer.LanguageServerInstance(stdin, stdout, project_path, depot_path)
      server.runlinter = true
      run(server)
    ]],
  },

  filetypes = { 'julia' },
  root_dir = find_root { 'Project.toml', 'JuliaProject.toml', '.git' },

  on_attach = function(_, bufnr)
    vim.api.nvim_buf_create_user_command(bufnr, 'LspJuliaActivateEnv', function(opts)
      activate_env(opts.args)
    end, {
      desc = 'Activate a Julia environment',
      nargs = '?',
      complete = 'file',
    })
  end,
}

return M

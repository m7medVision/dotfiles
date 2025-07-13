return {
  {
    'milanglacier/minuet-ai.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
    config = function()
      require('minuet').setup {
        virtualtext = {
          auto_trigger_ft = { '*' },
          keymap = {
            accept = '<A-a>', -- Accept the entire virtual text completion.
            accept_line = '<A-l>', -- Accept only the current line of the completion.
            accept_n_lines = '<A-z>',
            prev = '<A-p>', -- Cycle to the previous completion item (if multiple).
            next = '<A-n>', -- Cycle to the next completion item (if multiple).
            dismiss = '<A-e>', -- Dismiss (hide) the current virtual text completion.
          },
          show_on_completion_menu = false,
        },
        provider = 'openai_fim_compatible',
        n_completions = 3,
        context_window = 512,
        provider_options = {
          openai_fim_compatible = {
            api_key = 'TERM',
            name = 'Ollama',
            end_point = 'http://localhost:11434/v1/completions',
            model = 'qwen2.5-coder:1.5b',
            optional = {
              max_tokens = 56,
              top_p = 0.9,
            },
          },
        },
      }
    end,
  },
}

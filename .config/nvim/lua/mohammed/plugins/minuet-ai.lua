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
        -- Set the default provider you want to use on startup
        -- provider = 'openai_fim_compatible', -- Or 'openai_compatible' to use Groq by default
        provider = 'openai_compatible',
        n_completions = 3,
        context_window = 512,
        provider_options = {
          -- this is local backup
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
          -- this is online backup for github
          openai_compatible = {
            api_key = 'GROQ_API_KEY',
            name = 'Groq',
            end_point = 'https://api.groq.com/openai/v1/chat/completions',
            model = 'gemma2-9b-it',
            stream = true,
            optional = {
              max_tokens = 1024,
              top_p = 1,
              temperature = 1,
            },
          },
        },
      }
    end,
  },
}

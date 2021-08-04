module.exports = {
  theme: {
    screens: {
      'sm': '640px',
      'md': '768px',
      'lg': '1024px',
      'xl': '1280px',
      '2xl': '1536px',
      'toc': "1337px",
    },
    extend: {
      spacing: {
        'sidenotes': '258px',
        'articles': '666px',
        'm_articles': '683px',
      }
    },
    wider: {
      center: true,
      padding: "1rem",
      screens: {
        lg: "1200px",
        xl: "1300px",
        "2xl": "1800px",
      },
    },
    container: {
      center: true,
      padding: "1rem",
      screens: {
        lg: "1124px",
        xl: "1124px",
        "2xl": "1124px",
      },
    },
    colors: {
      transparent: 'transparent',
      current: 'currentColor',
      accent: {
        light: '#c37b73',
        DEFAULT: '#a96060',
        dark: '#904b4b'
      },
      pink: {
        light: '#c37b73',
        DEFAULT: '#a96060',
        dark: '#904b4b'
      },
      black: {
        light: '#212121',
        DEFAULT: '#161616',
        dark: '#000000'
      },
      mute: {
        light: '#a9a0a0',
        DEFAULT: '#787070',
        dark: '#535353'
      },
      grey: {
        light: '#a9a0a0',
        DEFAULT: '#787070',
        dark: '#535353'
      },
      white: {
        light: '#ffffff',
        DEFAULT: '#fffafa',
        dark: '#fff0f0'
      },

      dracula: {
        background: '#282a36',
        //           ^---------- vamp.dark
        foreground: '#f8f8f2'
        //           ^---------- snowdrop
      },
      vamp: {
        light: '#6272a4',
        DEFAULT: '#44475a',
        dark: '#282a36'
      },
      synthwave: {
        light: '#8be9fd',
        teal: '#8be9fd',

        DEFAULT: '#ff79c6',
        pink: '#ff79c6',

        dark: '#bd93f9',
        violet: '#bd93f9'
      },
      dune: {
        light: '#f1fa8c',
        sun: '#f1fa8c',

        DEFAULT: '#ffb86c',
        sand: '#ffb86c',

        dark: '#ff5555',
        spice: '#ff5555'
      },
      snowdrop: {
        light: '#ffffff',
        DEFAULT: '#f8f8f2',
        dark: '#50fa7b'
      }
    },
  },
  variants: {
    extend: {
      padding: ['hover'],
    },
  },
  plugins: [],
  purge: [
    '../lib/**/*.ex',
    '../lib/**/*.leex',
    '../lib/**/*.eex',
    './js/**/*.js'
  ],
};

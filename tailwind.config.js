/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./templates/**/*.{html,js}",
    "./**/*.py",
    "./static/**/*.js",
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        brand: {
          navy: "#0A192F",
          blue: "#1E90FF",
          slate: "#2F3E46",
          success: "#00B894",
          warning: "#FFB400",
          critical: "#D62828",
          cloud: "#F5F6FA",
        }
      },
      borderRadius: {
        'xl': '12px',
        '2xl': '16px'
      },
      boxShadow: {
        'card': '0 2px 6px rgba(0,0,0,0.15)'
      }
    },
  },
  plugins: [],
};

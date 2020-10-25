module.exports = {
  root: true,
  extends: '@react-native-community',
  plugins: ['import'],
  rules: {
    // disabled rules
    'prettier/prettier': 'off',
    'react-native/no-inline-styles': 'off',
    'no-fallthrough': 'off',
    curly: 'off',
    // error rules
    semi: 'error',
    'key-spacing': [2, { beforeColon: false, afterColon: true }],
    'require-await': 'error',
    indent: [
      'error',
      2,
      {
        ignoredNodes: ['TemplateLiteral'], // https://github.com/babel/babel-eslint/issues/681#issuecomment-451336031
        SwitchCase: 1,
      },
    ],
    'no-console': 'error',
    'no-debugger': 'error',
    'prefer-const': 'error',
    'no-multiple-empty-lines': 'error',
    'no-unused-vars': 'error',
    'no-trailing-spaces': 'error',
    'brace-style': ['error', '1tbs', { allowSingleLine: true }],
    'react/jsx-boolean-value': 'error',
    'react/jsx-closing-bracket-location': 'error',
    'react/jsx-max-props-per-line': ['error', { maximum: 1, when: 'multiline' }],
    'max-len': [
      'error',
      {
        code: 120,
        ignoreTemplateLiterals: true,
        // FIXME: doesn't work :/
        ignorePattern: '^log\\(', // ignore "log('...')"
        ignoreUrls: true, // ignore long urls
      },
    ],
    'import/no-unresolved': ['error', { commonjs: true, amd: true }],
    'import/named': 'error',
    'import/namespace': 'error',
    'import/default': 'error',
    'import/export': 'error',
  },
  settings: {
    'import/ignore': ['node_modules/react-native/index\\.js$'], // https://github.com/facebook/react-native/issues/28549
    'import/resolver': {
      node: {
        extensions: ['.js', '.ts', '.android.js', '.ios.js'],
      },
    },
  },
  globals: {
    WebSocket: true,
    URLSearchParams: true,
  },
};

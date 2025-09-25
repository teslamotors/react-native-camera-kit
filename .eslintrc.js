module.exports = {
  root: true,
  parser: '@typescript-eslint/parser',
  extends: '@react-native',
  plugins: ['import', 'tsdoc', '@typescript-eslint'],
  reportUnusedDisableDirectives: true,
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
    'no-unused-vars': 'off',
    '@typescript-eslint/no-unused-vars': ['error', { 'vars': 'all', 'args': 'after-used', 'ignoreRestSiblings': true }],
    'no-trailing-spaces': 'error',
    'brace-style': ['error', '1tbs', { allowSingleLine: true }],
    'react/jsx-boolean-value': 'error',
    'react/jsx-closing-bracket-location': 'error',
    'react/jsx-max-props-per-line': ['error', { maximum: 1, when: 'multiline' }],
    'max-len': [
      'error',
      {
        code: 120,
        ignoreComments: true, // allow longer TSDoc/comment lines
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
    // typescript-eslint v8 removed extension rules. Map to base rules to preserve behavior
    '@typescript-eslint/func-call-spacing': 'off',
    'func-call-spacing': ['error', 'never'],
    // TSDoc is enforced via an override on TS/TSX files only (see overrides)
  },
  settings: {
    'import/ignore': ['node_modules/react-native/index\\.js$'], // https://github.com/facebook/react-native/issues/28549
    'import/resolver': {
      node: {
        extensions: ['.js', '.ts', '.tsx', '.android.js', '.ios.js', '.android.tsx', '.ios.tsx'],
      },
    },
  },
  globals: {
    WebSocket: true,
    URLSearchParams: true,
  },
  // Targeted relief for specs: avoid import plugin traversing RN internals
  overrides: [
    // Enforce TSDoc only for TypeScript sources in src/
    {
      files: ['src/**/*.{ts,tsx}'],
      rules: {
        'tsdoc/syntax': 'error',
      },
    },
    {
      files: ['src/specs/**/*.ts'],
      rules: {
        // Turn off import rules that resolve into RN internals and crash parsers
        'import/named': 'off',
        'import/no-unresolved': 'off',
      },
      settings: {
        // Treat RN internals as core so import plugin won't try to resolve/parse them
        'import/core-modules': [
          'react-native/Libraries/Types/CodegenTypes',
          'react-native/Libraries/Utilities/codegenNativeComponent',
        ],
      },
    },
    // Node scripts: allow console and relax max-len for long regex/HTML strings
    {
      files: ['scripts/**/*.mjs'],
      rules: {
        'no-console': 'off',
        'no-useless-escape': 'off',
        quotes: 'off',
        '@typescript-eslint/no-unused-vars': 'off',
        'max-len': [
          'error',
          {
            code: 200,
            ignoreStrings: true,
            ignoreTemplateLiterals: true,
            ignoreUrls: true,
          },
        ],
      },
    },
  ],
};

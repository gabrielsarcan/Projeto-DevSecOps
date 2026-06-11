import js from "@eslint/js";
import pluginSecurity from "eslint-plugin-security";
import globals from "globals";

export default [
    js.configs.recommended,
    pluginSecurity.configs.recommended,
    {
        files: ["**/*.js", "../game/src/**/*.js"],
        languageOptions: {
            ecmaVersion: "latest",
            sourceType: "script",
            globals: {
                ...globals.browser,
                ...globals.node,
                ...globals.jest,
                io: "readonly",
                mk: "writable",
                Movement: "readonly"
            }
        },
        rules: {
            "no-unused-vars": "warn",
            "no-extra-semi": "off"
        }
    }
];

#!/bin/bash

echo "Setup Project: running..."

#Start project with npm
npm init --y
echo "Project has been started with Yarn Package Manager ✅"


#Install Typescript
npm install typescript -D
echo "Typescript installed! ✅"


#Install necessary libraries to start an NodeJS api
npm install cors express jsonwebtoken module-alias rimraf uuid
echo "Libs has been installed with successfull ✅"


#Install types from libraries to build setup
npm install @types/cors @types/express @types/jsonwebtoken @types/module-alias @types/uuid -D
echo "Essentials libraries has been installed ✅"


#Install codestyle libraries
npm install husky lint-staged eslint eslint-config-standard-with-typescript eslint-plugin-import eslint-plugin-node eslint-plugin-promise @typescript-eslint/eslint-plugin -D
echo "Codestyle libraries installed with successfull ✅"


#Install libraries to testing
npm install jest @types/jest @types/supertest @types/node jest-mock-extended supertest ts-jest ts-node-dev @jest-mock/express -D
echo "Test libraries has been installed ✅"

npm set-script start "node build/main/server.js"
npm set-script build "npm run clean && tsc -p tsconfig-build.json",
npm set-script debug "nodemon -L --watch ./dist --inspect=0.0.0.0:9222 --nolazy -r dotenv/config ./dist/main/server.js",
npm set-script clean "rimraf build"
npm set-script prepare "husky install"
npm set-script test "jest --passWithNoTests --silent --no-cache --runInBand"
npm set-script "test:ci" "npm run test -- --coverage"
npm set-script "test:unit" "npm run test -- --watch -c jest-unit-config.js"
npm set-script "test:staged": "npm run test -- --findRelatedTests"
npm set-script "test:verbose": "jest --passWithNoTests --runInBand"
npm set-script "test:coverrals": "npm run test:ci && coveralls < coverage/lcov.info"
npm set-script "test:integration": "npm run test -- --watch -c jest-integration-config.js"
echo "Set scripts of app"

echo "First Step: FINISH! ✅"

#=================================================================================================#

echo "Second Step: running..."

#Make source directory
mkdir src


#Make documentation directory following Software Engineering theory
mkdir documentation


#Make test directory
mkdir tests


#Add gitignore
touch .gitignore
echo "node_modules
dist
coverage
.env" > .gitignore


#Make directories by Clean Architecture
cd src && mkdir application
mkdir domain
mkdir infra
mkdir main
cd ..

cd tests && mkdir application
mkdir domain
mkdir infra
cd ..
echo "Second Step: FINISH! ✅"

#=================================================================================================#

echo "Third Step: running..."

#Make typescript config file and write inside himself
tsconfig='{
  "compilerOptions": {
    "incremental": true,
    "outDir": "dist",
    "rootDirs": ["src", "tests"],
    "target": "es2021",
    "sourceMap": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "module": "commonjs",
    "moduleResolution": "node",
    "esModuleInterop": true,
    "baseUrl": "src",
    "paths": {
      "@domain/*": ["domain/*"],
      "@main/*": ["main/*"],
      "@infra/*": ["infra/*"],
      "@application/*": ["application/*"],
      "@tests/*": ["../tests/*"]
    },
    "strict": true,
    "noImplicitOverride": true,
    "removeComments": true,
    "emitDecoratorMetadata": true,
    "experimentalDecorators": true
  },
  "include": ["src", "tests"]
}'
echo "$tsconfig" > tsconfig.json


#Make file to exclude test directory of build
tsconfigtest='{
  "extends": "./tsconfig.json",
  "exclude": ["tests"]
}'
echo "$tsconfigtest" > tsconfig-build.json


#Jest config (Default, Unit & Integration)
jestconfig="const { pathsToModuleNameMapper } = require('ts-jest/utils')
const { compilerOptions: { paths } } = require('./tsconfig.json')

module.exports = {
  collectCoverageFrom: [
    '<rootDir>/src/**/*.ts',
    '!<rootDir>/src/main/**',
    '!<rootDir>/src/**/index.ts',
    '!<rootDir>/src/infra/database/repositories/*.ts',
    '!<rootDir>/src/infra/database/entities/*.ts',
  ],
  coverageDirectory: 'coverage',
  moduleNameMapper: pathsToModuleNameMapper(paths, { prefix: '<rootDir>/src/' }),
  testMatch: ['**/*.spec.ts'],
  roots: [
    '<rootDir>/src',
    '<rootDir>/tests'
  ],
  transform: {
    '\\.ts': 'ts-jest'
  },
  clearMocks: true
}"
echo "$jestconfig" > jest.config.js

jestintconfig='module.exports = {
  ...require("./jest.config.js"),
  testMatch: ["**/*.test.ts"]
}'
echo "$jestintconfig" > jest.integration.config.js

jestunitconfig="module.exports = {
  const config = require('./jest.config')
  config.testMatch = ['**/*.spec.ts']
  module.exports = config
}"
echo "$jestunitconfig" > jest.unit.config.js

#Module alias
modulealias='import { addAlias } from "module-alias"
import { resolve } from "path"
addAlias("@", resolve(process.env.TS_NODE_DEV === undefined ? "dist" : "src"))'
cd src/main
mkdir config && cd config
echo "$modulealias" > module-alias.ts
cd .. && cd .. && cd ..


#Editor Config File
editor='root = true
[*]
indent_style = space
indent_size = 2
end_of_line = lf
charset = utf-8
trim_trailing_whitespace = true
insert_final_newline = true'
echo "$editor" > .editorconfig


#Eslint ignore
editor='.husky
.vscode
coverage
dist
documentation
node_modules
public'
echo "$editor" > .eslintignore


#Eslint json config
eslintconfig='{
  "extends": "standard-with-typescript",
  "parserOptions": {
    "project": "./tsconfig.json"
  },
  "rules": {
    "@typescript-eslint/consistent-type-definitions": "off",
    "@typescript-eslint/no-namespace": "off",
    "@typescript-eslint/return-await": "off",
    "@typescript-eslint/no-non-null-assertion": "off"
  }
}'
echo "$eslintconfig" > .eslintrc.json


#Lint staged
lintstaged='{
  "*.ts": [
    "npm run lint:fix",
    "npm run test:staged"
  ]
}'
echo "$lintstaged" > .lintstagedrc.json

npm run prepare
npx husky add .husky/pre-commit "npx lint-staged"
npx husky add .husky/pre-push "npm run test:ci"
echo "Configure Husky"
#Initializing repository and switch to main branch
git init
git branch -M main
git checkout -b develop
git checkout main
git add .
git commit -m "chore: Initial setup environment to Development"

#=================================================================================================#

#Github actions - Basic run node & tests
mkdir .github
cd .github && mkdir workflows && cd workflows
workflow='name: CI Tests
on:
  push:
    branches:
      - main
      - develop
  pull_request:
    branches:
      - main
      - develop
jobs:
  test-ci:
    runs-on: ubuntu-20.04
    strategy:
      matrix:
        node-version: [14.x, 16.x, 18.x]
        # See supported Node.js release schedule at https://nodejs.org/en/about/releases/
    steps:
    - uses: actions/checkout@v2
    - name: Use Node.js ${{ matrix.node-version }}
      uses: actions/setup-node@v2
      with:
        node-version: ${{ matrix.node-version }}
    - run: npm ci
    - run: npm run test'
echo "$workflow" > full-workflow.yml
cd .. & cd ..

echo "Setup Project: finished ✅"

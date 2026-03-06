# FlutterMint Examples

## Create a new project

```bash
# Interactive wizard
fluttermint create

# Quick create with defaults
fluttermint create my_app
```

## Add and remove modules

```bash
fluttermint add routing
fluttermint add theming
fluttermint remove toast
fluttermint status
```

## Add a preference

```bash
# Add a typed preference (requires preferences module)
fluttermint pref add userEmail String
fluttermint pref add darkMode bool
```

## Add a database table

```bash
# Add a table with columns (requires database module)
fluttermint db add users -c name:String -c email:String -c age:int
fluttermint db add tasks -c title:String -c completed:bool
```

## Generate a screen

```bash
# Basic screen
fluttermint screen profile

# Screen with route parameters
fluttermint screen product --param id:String --param category:String
```

## Manage platforms

```bash
fluttermint platform add web macos
```

## Run and build

```bash
fluttermint run
fluttermint build
```

## Configure CI/CD

```bash
fluttermint config cicd
```

## Configure flavors

```bash
fluttermint config flavors
```

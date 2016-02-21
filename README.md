# Drd

**A Telegram bot for automating your life**

## Installation
```
  $ git clone https://github.com/marvelm/drd.git
  $ cd drd
```
Next, you need a [Telegram Bot API token](https://core.telegram.org/bots#create-a-new-bot) and put it in a file called `token`. You can use the following script and replace `MY_TOKEN` with something like `123456789:ABCNhyBzasdasdaV0s12313Ag3LYaIab1oe`
```
  $ echo MY_TOKEN > token
  $ mix deps.get
  $ mix deps.compile
  $ mix compile
  $ mix amnesia.create -db Database --disk
```

## Running
Running Drd is as simple as `mix run --no-halt`.

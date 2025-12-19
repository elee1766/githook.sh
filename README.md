# [githook.sh](https://githook.sh)

simple lightweight git hooks. portable, small[,](https://www.youtube.com/watch?v=P_i1xk07o4g) and easy. inspired by [husky](https://github.com/typicode/husky).

## quick install

```
curl -sSL https://githook.sh | sh
```

or with wget:

```
wget -qO- https://githook.sh | sh
```

for more info, go to [githook.sh](https://githook.sh)

## how it works / what it does

you put a `githook.sh` file in the base of your repo (this is setup by that one liner above).

then you can get people to just run `./githook.sh install`, and it will setup git hooks.

there is also integration if it sees a package.json, it will try to add a script to your package.json called `prepare` which runs `./githook.sh install`

## goal

the idea is that now we can have husky, but for every repo and every language, since it's just a 300 line shell script that exists in the root of your repo that you can hook up to whatever other things you have in your repo

## contribution info

so there is very primative bundling, aka we cat all the files together to build.

happy to accept any contributions.

ideally we can keep line count down and the api simple so that its not so complicated.

probably language support is the thing to add.


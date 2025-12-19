# [githook.sh](https://githook.sh)

git hooks made easier. simple, lightweight[,](https://www.youtube.com/watch?v=P_i1xk07o4g) and portable. inspired by [husky](https://github.com/typicode/husky).

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

you put a `.githook.sh` file in the base of your repo (this is setup by that one liner above).

then you can get people to just run `./.githook.sh install`, and it will setup git hooks.

there is also integration if it sees a package.json, it will try to add a script to your package.json called `prepare` which runs `./githook.sh install`

## goals / why

i really like husky. but i wanted something that i could use in non-javascript repos without introducing npm

other options exist, but they all require you to install some binary in go/rust, and either have this big binary live in your repo, or force everyone to download said binary

so the hope is that with this easy to remember domain and a single-line curl command, we can vendor a relatively small shell script with minimal functionality but properly setups and standardizes hooks, like what husky did for js, but for everything.

there is no real innovation here. basically everything is copied from husky.

## contribution info

so there is very primative bundler, aka we cat all the files together to build lol.

happy to accept any contributions.

ideally we can keep line count down and the api simple so that its not so complicated.

probably language support is the thing to add.


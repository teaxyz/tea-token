# Tea.xyz Token Contract

### Tokens

#### `src/TeaToken/Tea.sol`

The primary tea token.

Minting permissions controlled by the `registry.owner()` with a minter role being given to the `TeaMasterChef` contract by the factory.

A minting cap (not a supply cap due to burning) is hardcoded.





## Dev Dependencies

This repo uses PaulRBerg's foundry-template.

- [node](https://nodejs.org/en)
- [pnpm](https://pnpm.io/installation)
- [rust](https://www.rust-lang.org/tools/install)
- [foundry](https://book.getfoundry.sh/getting-started/installation)


## Writing Tests

To write a new test contract, you start by importing [PRBTest](https://github.com/PaulRBerg/prb-test) and inherit from
it in your test contract. PRBTest comes with a pre-instantiated [cheatcodes](https://getfoundry.sh/reference/cheatcodes/overview)
environment accessible via the `vm` property. If you would like to view the logs in the terminal output you can add the
`-vvv` flag and use [console.log](https://getfoundry.sh/reference/forge-std/console-log.html).


## Usage

This is a list of the most frequently needed commands.

### Build

Build the contracts:

```sh
forge build
```

### Clean

Delete the build artifacts and cache directories:

```sh
forge clean
```

### Compile

Compile the contracts:

```sh
forge build
```

### Coverage

Get a test coverage report:

```sh
forge coverage
```

### Format

Format the contracts:

```sh
forge fmt
```

### Gas Usage

Get a gas report:

```sh
forge test --gas-report
```

### Lint

Lint the contracts:

```sh
pnpm lint
```

### Test

Run the tests:

```sh
forge test
```

## Notes

1. Foundry uses [git submodules](https://git-scm.com/book/en/v2/Git-Tools-Submodules) to manage dependencies. For
   detailed instructions on working with dependencies, please refer to the
   [guide](https://book.getfoundry.sh/projects/dependencies.html) in the book
2. You don't have to create a `.env` file, but filling in the environment variables may be useful when debugging and
   testing against a fork.


## License

This project is licensed under Apache License, Version 2.0.

## Example ERC-1271/EIP-2612/V-3009 with and without EOA support

See TEXT_VECTORS.md
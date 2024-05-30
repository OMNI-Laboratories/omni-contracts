<div align="center">
  <img src="images/omni-logo.png" alt="OMNI Laboratories" height="140px" style="border-radius: 20px;">
</div>

---

# OMNI Contracts

[![Docs](https://img.shields.io/badge/OMNI-%F0%9F%93%84-purple)](TODO)
![forge](https://img.shields.io/badge/forge-0.2.0-brown)
![solidity](https://img.shields.io/badge/solidity-^0.8.25-red)
![coverage](https://img.shields.io/badge/coverage-100%25-brightgreen)
![comments](https://img.shields.io/badge/comments->80%25-yellow)

[![Docs](https://img.shields.io/badge/OpenZeppelin-%F0%9F%93%84-blue)](https://docs.openzeppelin.com/contracts)
[![NPM Package](https://img.shields.io/npm/v/@openzeppelin/contracts.svg)](https://www.npmjs.org/package/@openzeppelin/contracts)

```shell
npm install
```

## Running Tests

Contracts that are used for testing should be labeled with the `Test` prefix. Those that are representative of a live contract, but are augmented for easier tested should be labeled with the `Mock` prefix.

To get started, all you should need to install dependencies and run the unit tests are here.

```shell
forge test
forge test -vvv --match-contract [ContractName] --match-test [TestName]
```

```shell
forge coverage
forge coverage --report lcov
```

Coverage Gutters
`⌘ shift 7` || `ctrl shift 7`

```txt
  /######  /##      /## /##   /## /######       /##        /######  /#######   /###### 
 /##__  ##| ###    /###| ### | ##|_  ##_/      | ##       /##__  ##| ##__  ## /##__  ##
| ##  \ ##| ####  /####| ####| ##  | ##        | ##      | ##  \ ##| ##  \ ##| ##  \__/
| ##  | ##| ## ##/## ##| ## ## ##  | ##        | ##      | ########| ####### |  ###### 
| ##  | ##| ##  ###| ##| ##  ####  | ##        | ##      | ##__  ##| ##__  ## \____  ##
| ##  | ##| ##\  # | ##| ##\  ###  | ##        | ##      | ##  | ##| ##  \ ## /##  \ ##
|  ######/| ## \/  | ##| ## \  ## /######      | ########| ##  | ##| #######/|  ######/
 \______/ |__/     |__/|__/  \__/|______/      |________/|__/  |__/|_______/  \______/ 
```

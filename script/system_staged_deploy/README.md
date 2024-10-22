# Dev Deploy

## Tasks

If using ledger device add `--ledger --hd-paths "m/44'/60'/0'/0/0"` prior to `--broadcast`

### deploy-tea

```sh
forge script script/system_staged_deploy/1_TeaToken_Deploy.s.sol --broadcast --rpc-url ${BASE_SEPOLIA_RPC} --sender ${SENDER_ADDRESS}
```

### deploy-implementations

```sh
forge script script/system_staged_deploy/2_a_Factory_Implementations_Deploy.s.sol --broadcast --rpc-url ${BASE_SEPOLIA_RPC} --sender ${SENDER_ADDRESS}
```

```sh
forge script script/system_staged_deploy/2_b_Registry_Implementations_Deploy.s.sol --broadcast --rpc-url ${BASE_SEPOLIA_RPC} --sender ${SENDER_ADDRESS}
```

```sh
forge script script/system_staged_deploy/2_c_Staking_Implementations_Deploy.s.sol --broadcast --rpc-url ${BASE_SEPOLIA_RPC} --sender ${SENDER_ADDRESS}
```

```sh
forge script script/system_staged_deploy/2_e_StakedTea_Implementations_Deploy.s.sol --broadcast --rpc-url ${BASE_SEPOLIA_RPC} --sender ${SENDER_ADDRESS}
```

### deploy-factory

```sh
forge script script/system_staged_deploy/3_Factory_Deploy.s.sol --broadcast --rpc-url ${BASE_SEPOLIA_RPC} --sender ${SENDER_ADDRESS}
```

### deploy-system-contracts

```sh
forge script script/system_staged_deploy/4_SystemContracts_Deploy.s.sol --broadcast --rpc-url ${BASE_SEPOLIA_RPC} --sender ${SENDER_ADDRESS}
```

### deploy-distributor

```sh
forge script script/system_staged_deploy/5_Distributor_Deploy.s.sol --broadcast --rpc-url ${BASE_SEPOLIA_RPC} --sender ${SENDER_ADDRESS}
```

### config-contracts

```sh
forge script script/system_staged_deploy/6_ConfigContracts.s.sol --broadcast --rpc-url ${BASE_SEPOLIA_RPC} --sender ${SENDER_ADDRESS}
```

### send-tokens

```sh
forge script script/system_staged_deploy/99_SendTokens.s.sol --broadcast --rpc-url ${BASE_SEPOLIA_RPC} --sender ${SENDER_ADDRESS}
```

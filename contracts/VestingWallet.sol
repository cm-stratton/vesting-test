// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (finance/VestingWallet.sol)
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {console} from "hardhat/console.sol";

/**s
 * @dev A vesting wallet is an ownable contract that can receive native currency and ERC20 tokens, and release these
 * assets to the wallet owner, also referred to as "beneficiary", according to a vesting schedule.
 *
 * Any assets transferred to this contract will follow the vesting schedule as if they were locked from the beginning.
 * Consequently, if the vesting has already started, any amount of tokens sent to this contract will (at least partly)
 * be immediately releasable.
 *
 * By setting the duration to 0, one can configure this contract to behave like an asset timelock that hold tokens for
 * a beneficiary until a specified time.
 *
 * NOTE: Since the wallet is {Ownable}, and ownership can be transferred, it is possible to sell unvested tokens.
 * Preventing this in a smart contract is difficult, considering that: 1) a beneficiary address could be a
 * counterfactually deployed contract, 2) there is likely to be a migration path for EOAs to become contracts in the
 * near future.
 *
 * NOTE: When using this contract with any token whose balance is adjusted automatically (i.e. a rebase token), make
 * sure to account the supply/balance adjustment in the vesting schedule to ensure the vested amount is as intended.
 */
contract VestingWallet is Context, Ownable {
    event EtherReleased(uint256 amount);
    event ERC20Released(address indexed token, uint256 amount);

    uint256 private _released;
    mapping(address token => uint256) private _erc20Released;
    uint64 private immutable _start;
    uint64 private immutable _duration;
    uint64 private immutable _interval;

    mapping(address => uint64) _lastReleased;

    /**
     * @dev Sets the sender as the initial owner, the beneficiary as the pending owner, the start timestamp and the
     * vesting duration of the vesting wallet.
     */
    constructor(
        address beneficiary,
        uint64 startTimestamp,
        uint64 durationSeconds,
        uint64 intveralSeconds
    ) payable Ownable(beneficiary) {
        _start = startTimestamp;
        _duration = durationSeconds;
        _interval = intveralSeconds;
    }

    /**
     * @dev The contract should be able to receive Eth.
     */
    receive() external payable virtual {}

    /**
     * @dev Getter for the start timestamp.
     */
    function start() public view virtual returns (uint256) {
        return _start;
    }

    /**
     * @dev Getter for the vesting duration.
     */
    function duration() public view virtual returns (uint256) {
        return _duration;
    }

    /**
     * @dev Getter for the end timestamp.
     */
    function end() public view virtual returns (uint256) {
        return start() + duration();
    }
    /**
     * @dev Amount of token already released
     */
    function released(address token) public view virtual returns (uint256) {
        return _erc20Released[token];
    }

    /**
     * @dev Getter for the amount of releasable `token` tokens. `token` should be the address of an
     * IERC20 contract.
     */
    function releasable(
        address user,
        address token
    ) public view virtual returns (uint256) {
        uint256 vested = vestedAmount(user, token, uint64(block.timestamp));
        return vested > 0 ? vested - released(token) : 0;
    }

    /**
     * @dev Release the tokens that have already vested.
     *
     * Emits a {ERC20Released} event.
     */
    function release(address token) public virtual {
        uint256 amount = releasable(msg.sender, token);
        console.log(amount);
        _erc20Released[token] += amount;
        emit ERC20Released(token, amount);
        SafeERC20.safeTransfer(IERC20(token), owner(), amount);
        _lastReleased[msg.sender] = uint64(block.timestamp);
        console.log(_lastReleased[msg.sender]);
    }
    /**
     * @dev Calculates the amount of tokens that has already vested. Default implementation is a linear vesting curve.
     */
    function vestedAmount(
        address user,
        address token,
        uint64 timestamp
    ) public view virtual returns (uint256) {
        return
            _vestingSchedule(
                user,
                IERC20(token).balanceOf(address(this)) + released(token),
                timestamp
            );
    }

    function _vestingSchedule(
        address user,
        uint256 totalAllocation,
        uint64 timestamp
    ) internal view virtual returns (uint256) {
        console.log(_lastReleased[user] + _interval <= timestamp);
        if (timestamp < start() || timestamp < start() + _interval) {
            return 0;
        } else if (timestamp >= end()) {
            return totalAllocation;
        } else {
            return
                _lastReleased[user] + _interval <= timestamp
                    ? (totalAllocation * (timestamp - start())) / duration()
                    : 0;
        }
    }
}

pragma solidity ^0.4.13;

import "./zeppelin-solidity/contracts/token/MintableToken.sol";
import "./zeppelin-solidity/contracts/math/SafeMath.sol";
import "./zeppelin-solidity/contracts/ownership/Claimable.sol";

/*
* Horizon State Decision Token Contract
*
* Version 0.9
*
* Author Nimo Naamani
*
* This smart contract code is Copyright 2017 Horizon State (https://Horizonstate.com)
*
* Licensed under the Apache License, version 2.0: http://www.apache.org/licenses/LICENSE-2.0
*
* @title Horizon State Token
* @dev ERC20 Decision Token (HST)
* @author Nimo Naamani
*
* HST tokens have 18 decimal places. The smallest meaningful (and transferable)
* unit is therefore 0.000000000000000001 HST. This unit is called a 'danni'.
*
* 1 HST = 1 * 10**18 = 1000000000000000000 dannis.
*
* Maximum total HST supply is 1 Billion.
* This is equivalent to 1000000000 * 10**18 = 1e27 dannis.
*
* HST are mintable on demand (as they are being purchased), which means that
* 1 Billion is the maximum.
*/
contract DecisionToken is MintableToken, Claimable {

  using SafeMath for uint256;

  // Name to appear in ERC20 wallets
  string public constant name = "Decision Token";

  // Symbol for the Decision Token to appear in ERC20 wallets
  string public constant symbol = "HST";

  // Version of the source contract
  string public constant version = "1.0";

  // Number of decimals for token display
  uint8 public constant decimals = 18;

  // Maximum total number of tokens ever created
  uint256 public constant tokenCap =  10**9 * 10**uint256(decimals);

  // Initial HorizonState allocation (reserve)
  uint256 public constant tokenReserve = 4 * (10**8) * 10**uint256(decimals);

  // Release timestamp - tokens can not be transfered before this time.
  uint256 public releaseTime;

  /**
   * @dev modifier to allow actions only when the token can be released
   */
  modifier onlyWhenReleased() {
    require(mintingFinished);
    require(now >= releaseTime);
    _;
  }

  /**
  * @dev Constructor for the DecisionToken.
  *
  * The contract shall assign the initial tokenReserve to Horizon State.
  */
  function DecisionToken(uint256 _releaseTime) MintableToken() {
    require(_releaseTime > now);
    releaseTime = _releaseTime;
    owner = msg.sender;
    totalSupply = tokenReserve;
    balances[owner] = totalSupply;
    Mint(owner, totalSupply);
  }

  // @dev override the transfer() function to only work when released
  function transfer(address _to, uint256 _value) onlyWhenReleased returns (bool) {
    return super.transfer(_to, _value);
  }

  // @dev override the transferFrom() function to only work when released
  function transferFrom(address _from, address _to, uint256 _value) onlyWhenReleased returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

}

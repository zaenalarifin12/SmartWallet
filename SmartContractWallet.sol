// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract Consumer {
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function deposit() public payable {}
}

contract SmartContractWallet {
    address payable public owner;

    mapping(address => uint256) public allowance;
    mapping(address => bool) public isAllowedToSend;

    mapping(address => bool) public guardians;
    address payable nextOwner;
    mapping(address => mapping(address => bool)) nextOWnerGuardianVoteBool;
    uint256 guardiantsResetCount;
    uint256 public constant confirmationsFromGuardiantsForReset = 3;

    constructor() {
        owner = payable(msg.sender);
    }

    function setGuardian(address _guardian, bool _isGuardian) public {
        require(msg.sender == owner, "you are not the owner, aborting");
        guardians[_guardian] = _isGuardian;
    }

    function proposeNewOwner(address payable _newOwner) public {
        require(guardians[msg.sender], "you are not the owner, aborting");
        require(
            nextOWnerGuardianVoteBool[_newOwner][msg.sender] == false,
            "you already voted, aborting"
        );

        if (_newOwner != nextOwner) {
            nextOwner = _newOwner;
            guardiantsResetCount = 0;
        }

        guardiantsResetCount++;

        if (guardiantsResetCount >= confirmationsFromGuardiantsForReset) {
            owner = nextOwner;
            nextOwner = payable(address(0));
        }
    }

    function setAllowance(address _for, uint256 _amount) public {
        require(msg.sender == owner, "you are not the owner, aborting");
        allowance[_for] = _amount;

        if (_amount > 0) {
            isAllowedToSend[_for] = true;
        } else {
            isAllowedToSend[_for] = false;
        }
    }

    function transfer(
        address payable _to,
        uint256 _amount,
        bytes memory _payload
    ) public returns (bytes memory) {
        // require(msg.sender == owner, "you are not the owner, aborting");
        if (msg.sender != owner) {
            require(
                isAllowedToSend[msg.sender],
                "you are not allowed to senda anything from this smart contract, aborting"
            );
            require(
                allowance[msg.sender] >= _amount,
                "you are trying to send more than you are allowed to, aborting "
            );

            allowance[msg.sender] -= _amount;
        }

        (bool success, bytes memory returnData) = _to.call{value: _amount}(
            _payload
        );
        require(success, "Aborting call not successfully");
        return returnData;
    }

    receive() external payable {}
}

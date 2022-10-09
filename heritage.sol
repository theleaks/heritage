// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Heritage {
    event Launch(
        string name,
        address creator,
        address heir,
        uint256 amount,
        uint256 endAt,
        bool claimed
    );

    event Claim(uint256 id);

    event Cancel(uint256 id);

    struct heritageContract {
        string name;
        address creator;
        address heir;
        uint256 amount;
        uint256 endAt;
        bool claimed;
    }

    mapping(address => heritageContract[]) public heritages;

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function createHeritage(
        string calldata name,
        address heir,
        uint256 endAt
    ) external payable {
        heritages[msg.sender].push(
            heritageContract({
                name: name,
                creator: msg.sender,
                heir: heir,
                amount: msg.value,
                endAt: block.timestamp + (endAt * 1 days),
                claimed: false
            })
        );
        emit Launch(
            name,
            msg.sender,
            heir,
            msg.value,
            block.timestamp + (endAt * 1 days),
            false
        );
    }

    function cancelHeritage(uint256 id) external {
        require(id < heritages[msg.sender].length, "index out of bound");
        uint256 amount = heritages[msg.sender][id].amount;
        if (amount > 0) {
            heritages[msg.sender][id].amount = 0;
            payable(msg.sender).transfer(amount);
        }

        for (uint256 i = id; i < heritages[msg.sender].length - 1; i++) {
            heritages[msg.sender][i] = heritages[msg.sender][i + 1];
        }
        heritages[msg.sender].pop();

        emit Cancel(id);
    }

    function claim(address creator, uint256 id) external isHeir(creator, id) isTimeUp(creator, id) {
        uint256 amount = heritages[creator][id].amount;
        if (amount > 0) {
            heritages[creator][id].amount = 0;
            payable(msg.sender).transfer(amount);
        }

        for (uint256 i = id; i < heritages[creator].length - 1; i++) {
            heritages[creator][i] = heritages[creator][i + 1];
        }
        heritages[creator].pop();

        emit Claim(id);
    }

    modifier isHeir(address creator, uint256 id) {
        require(heritages[creator][id].heir == msg.sender, "Heir is not valid");
        _;
    }
    modifier isTimeUp(address creator, uint256 id) {
        require(heritages[creator][id].endAt <= block.timestamp, "Heritage has not expired.");
        _;
    }
}

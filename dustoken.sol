pragma solidity ^0.5.10;

// 
// 
// Game specific details will be entered prior to deployment XXX
// 
// 
// This is the contract for gravity.game DUST Token
// 
// 
// 

contract Ownable {
    address public owner;

    event TransferOwnership(address _from, address _to);

    constructor() public {
        owner = msg.sender;
        emit TransferOwnership(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    function setOwner(address _owner) external onlyOwner {
        emit TransferOwnership(owner, _owner);
        owner = _owner;
    }
}

pragma solidity ^0.5.10;


contract StorageUnit {
    address private owner;
    mapping(bytes32 => bytes32) private store;

    constructor() public {
        owner = msg.sender;
    }

    function write(bytes32 _key, bytes32 _value) external {
        /* solium-disable-next-line */
        require(msg.sender == owner);
        store[_key] = _value;
    }

    function read(bytes32 _key) external view returns (bytes32) {
        return store[_key];
    }
}


pragma solidity ^0.5.10;


library IsContract {
    function isContract(address _addr) internal view returns (bool) {
        bytes32 codehash;
        /* solium-disable-next-line */
        assembly { codehash := extcodehash(_addr) }
        return codehash != bytes32(0) && codehash != bytes32(0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470);
    }
}

pragma solidity ^0.5.10;




library DistributedStorage {
    function contractSlot(bytes32 _struct) private view returns (address) {
        return address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        byte(0xff),
                        address(this),
                        _struct,
                        keccak256(type(StorageUnit).creationCode)
                    )
                )
            )
        );
    }

    function deploy(bytes32 _struct) private {
        bytes memory slotcode = type(StorageUnit).creationCode;
        /* solium-disable-next-line */
        assembly{ pop(create2(0, add(slotcode, 0x20), mload(slotcode), _struct)) }
    }

    function write(
        bytes32 _struct,
        bytes32 _key,
        bytes32 _value
    ) internal {
        StorageUnit store = StorageUnit(contractSlot(_struct));
        if (!IsContract.isContract(address(store))) {
            deploy(_struct);
        }

        /* solium-disable-next-line */
        (bool success, ) = address(store).call(
            abi.encodeWithSelector(
                store.write.selector,
                _key,
                _value
            )
        );

        require(success, "error writing storage");
    }

    function read(
        bytes32 _struct,
        bytes32 _key
    ) internal view returns (bytes32) {
        StorageUnit store = StorageUnit(contractSlot(_struct));
        if (!IsContract.isContract(address(store))) {
            return bytes32(0);
        }

        /* solium-disable-next-line */
        (bool success, bytes memory data) = address(store).staticcall(
            abi.encodeWithSelector(
                store.read.selector,
                _key
            )
        );

        require(success, "error reading storage");
        return abi.decode(data, (bytes32));
    }
}

pragma solidity ^0.5.10;


library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x + y;
        require(z >= x, "Add overflow");
        return z;
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256) {
        require(x >= y, "Sub underflow");
        return x - y;
    }

    function mult(uint256 x, uint256 y) internal pure returns (uint256) {
        if (x == 0) {
            return 0;
        }

        uint256 z = x * y;
        require(z / x == y, "Mult overflow");
        return z;
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256) {
        require(y != 0, "Div by zero");
        return x / y;
    }

    function divRound(uint256 x, uint256 y) internal pure returns (uint256) {
        require(y != 0, "Div by zero");
        uint256 r = x / y;
        if (x % y != 0) {
            r = r + 1;
        }

        return r;
    }
}

pragma solidity ^0.5.10;


library Math {
    function orderOfMagnitude(uint256 input) internal pure returns (uint256){
        uint256 counter = uint(-1);
        uint256 temp = input;

        do {
            temp /= 10;
            counter++;
        } while (temp != 0);

        return counter;
    }

    function min(uint256 _a, uint256 _b) internal pure returns (uint256) {
        if (_a < _b) {
            return _a;
        } else {
            return _b;
        }
    }

    function max(uint256 _a, uint256 _b) internal pure returns (uint256) {
        if (_a > _b) {
            return _a;
        } else {
            return _b;
        }
    }
}

pragma solidity ^0.5.10;


contract Energy {
    bytes32 private stub;

    modifier requestGas(uint256 _factor) {
        if (tx.gasprice == 0 || gasleft() > block.gaslimit) {
            uint256 startgas = gasleft();
            _;
            uint256 delta = startgas - gasleft();
            uint256 target = (delta * _factor) / 100;
            startgas = gasleft();
            while (startgas - gasleft() < target) {
                // Burn gas
                stub = keccak256(abi.encodePacked(stub));
            }
        } else {
            _;
        }
    }
}


pragma solidity ^0.5.10;


interface IERC20 {
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function balanceOf(address _owner) external view returns (uint256 balance);
}

pragma solidity ^0.5.10;

library AddressMinField {
    using AddressMinField for AddressMinField.Field;

    struct Field {
        uint256[] entries;
        mapping(address => uint256) index;
    }

    function initialize(Field storage _Field) internal {
        require(_Field.entries.length == 0, "already initialized");
        _Field.entries.push(0);
    }

    function encode(address _addr, uint256 _value) internal pure returns (uint256 _entry) {
        /* solium-disable-next-line */
        assembly {
            _entry := not(or(and(0xffffffffffffffffffffffffffffffffffffffff, _addr), shl(160, _value)))
        }
    }

    function decode(uint256 _entry) internal pure returns (address _addr, uint256 _value) {
        /* solium-disable-next-line */
        assembly {
            let entry := not(_entry)
            _addr := and(entry, 0xffffffffffffffffffffffffffffffffffffffff)
            _value := shr(160, entry)
        }
    }

    function decodeAddress(uint256 _entry) internal pure returns (address _addr) {
        /* solium-disable-next-line */
        assembly {
            _addr := and(not(_entry), 0xffffffffffffffffffffffffffffffffffffffff)
        }
    }

    function top(Field storage _Field) internal view returns(address, uint256) {
        if (_Field.entries.length < 2) {
            return (address(0), 0);
        }

        return decode(_Field.entries[1]);
    }

    function has(Field storage _Field, address _addr) internal view returns (bool) {
        return _Field.index[_addr] != 0;
    }

    function size(Field storage _Field) internal view returns (uint256) {
        return _Field.entries.length - 1;
    }

    function entry(Field storage _Field, uint256 _i) internal view returns (address, uint256) {
        return decode(_Field.entries[_i + 1]);
    }

    // RemoveMax pops off the root element of the Field (the highest value here) and rebalances the Field
    function popTop(Field storage _Field) internal returns(address _addr, uint256 _value) {
        // Ensure the Field exists
        uint256 FieldLength = _Field.entries.length;
        require(FieldLength > 1, "The Field does not exists");

        // take the root value of the Field
        (_addr, _value) = decode(_Field.entries[1]);
        _Field.index[_addr] = 0;

        if (FieldLength == 2) {
            _Field.entries.length = 1;
        } else {
            // Takes the last element of the array and put it at the root
            uint256 val = _Field.entries[FieldLength - 1];
            _Field.entries[1] = val;

            // Delete the last element from the array
            _Field.entries.length = FieldLength - 1;

            // Start at the top
            uint256 ind = 1;

            // vector down
            ind = _Field.vectorDown(ind, val);

            // Update index
            _Field.index[decodeAddress(val)] = ind;
        }
    }

    // Inserts adds in a value to our Field.
    function insert(Field storage _Field, address _addr, uint256 _value) internal {
        require(_Field.index[_addr] == 0, "The entry already exists");

        // Add the value to the end of our array
        uint256 encoded = encode(_addr, _value);
        _Field.entries.push(encoded);

        // Start at the end of the array
        uint256 currentIndex = _Field.entries.length - 1;

        // vector Up
        currentIndex = _Field.vectorUp(currentIndex, encoded);

        // Update index
        _Field.index[_addr] = currentIndex;
    }

    function update(Field storage _Field, address _addr, uint256 _value) internal {
        uint256 ind = _Field.index[_addr];
        require(ind != 0, "The entry does not exists");

        uint256 can = encode(_addr, _value);
        uint256 val = _Field.entries[ind];
        uint256 newInd;

        if (can < val) {
            // vector down
            newInd = _Field.vectorDown(ind, can);
        } else if (can > val) {
            // vector up
            newInd = _Field.vectorUp(ind, can);
        } else {
            // no changes needed
            return;
        }

        // Update entry
        _Field.entries[newInd] = can;

        // Update index
        if (newInd != ind) {
            _Field.index[_addr] = newInd;
        }
    }

    function vectorUp(Field storage _Field, uint256 _ind, uint256 _val) internal returns (uint256 ind) {
        // vector up
        ind = _ind;
        if (ind != 1) {
            uint256 source = _Field.entries[ind / 2];
            while (source < _val) {
                // If the source value is lower than our current value, we swap them
                (_Field.entries[ind / 2], _Field.entries[ind]) = (_val, source);

                // Update moved Index
                _Field.index[decodeAddress(source)] = ind;

                // change our current Index to go up to the source
                ind = ind / 2;
                if (ind == 1) {
                    break;
                }

                // Update source
                source = _Field.entries[ind / 2];
            }
        }
    }

    function vectorDown(Field storage _Field, uint256 _ind, uint256 _val) internal returns (uint256 ind) {
        // vector down
        ind = _ind;

        uint256 lenght = _Field.entries.length;
        uint256 target = lenght - 1;

        while (ind * 2 < lenght) {
            // get the current index of the spawnren
            uint256 j = ind * 2;

            // left spawn value
            uint256 leftspawn = _Field.entries[j];

            // Store the value of the spawn
            uint256 spawnValue;

            if (target > j) {
                // The source has two spawns 

                // Load right spawn value
                uint256 rightspawn = _Field.entries[j + 1];

                // Compare the left and right spawn.
                // if the rightspawn is greater, then point j to it's index
                // and save the value
                if (leftspawn < rightspawn) {
                    spawnValue = rightspawn;
                    j = j + 1;
                } else {
                    // The left spawn is greater
                    spawnValue = leftspawn;
                }
            } else {
                // The source has a single spawn ‍
                spawnValue = leftspawn;
            }

            // Check if the spawn has a lower value
            if (_val > spawnValue) {
                break;
            }

            // else swap the value
            (_Field.entries[ind], _Field.entries[j]) = (spawnValue, _val);

            // Update moved Index
            _Field.index[decodeAddress(spawnValue)] = ind;

            // and let's keep going down the Field
            ind = j;
        }
    }
}

pragma solidity ^0.5.10;



contract Field is Ownable {
    using AddressMinField for AddressMinField.Field;

    // Field
    AddressMinField.Field private Field;

    // Field events
    event JoinField(address indexed _address, uint256 _balance, uint256 _prevSize);
    event LeaveField(address indexed _address, uint256 _balance, uint256 _prevSize);

    uint256 public constant TOP_SIZE = 255;

    constructor() public {
        Field.initialize();
    }

    function topSize() external pure returns (uint256) {
        return TOP_SIZE;
    }

    function addressAt(uint256 _i) external view returns (address addr) {
        (addr, ) = Field.entry(_i);
    }

    function indexOf(address _addr) external view returns (uint256) {
        return Field.index[_addr];
    }

    function entry(uint256 _i) external view returns (address, uint256) {
        return Field.entry(_i);
    }

    function top() external view returns (address, uint256) {
        return Field.top();
    }

    function size() external view returns (uint256) {
        return Field.size();
    }

    function update(address _addr, uint256 _new) external onlyOwner {
        uint256 _size = Field.size();

        // If the Field is empty
        // join the _addr
        if (_size == 0) {
            emit JoinField(_addr, _new, 0);
            Field.insert(_addr, _new);
            return;
        }

        // Load top value of the Field
        (, uint256 lastBal) = Field.top();

        // If our target address already is in the Field
        if (Field.has(_addr)) {
            // Update the target address value
            Field.update(_addr, _new);
            // If the new value is 0
            // always pop the Field
            // we updated the Field, so our address should be on top
            if (_new == 0) {
                Field.popTop();
                emit LeaveField(_addr, 0, _size);
            }
        } else {
            // IF Field is full or new balance is higher than pop Field
            if (_new != 0 && (_size < TOP_SIZE || lastBal < _new)) {
                // If Field is full pop Field
                if (_size >= TOP_SIZE) {
                    (address _poped, uint256 _balance) = Field.popTop();
                    emit LeaveField(_poped, _balance, _size);
                }

                // Insert new value
                Field.insert(_addr, _new);
                emit JoinField(_addr, _new, _size);
            }
        }
    }
}

pragma solidity ^0.5.10;








contract DustToken is Ownable, GasPump, IERC20 {
    using DistributedStorage for bytes32;
    using SafeMath for uint256;

    event Winner(address indexed _addr, uint256 _value);

    // Adjustment Events
    event SetName(string _prev, string _new);
    event SetExtraGas(uint256 _prev, uint256 _new);
    event SetField(address _prev, address _new);
    event WhitelistFrom(address _addr, bool _whitelisted);
    event WhitelistTo(address _addr, bool _whitelisted);

    uint256 public totalSupply;

    bytes32 private constant BALANCE_KEY = keccak256("balance");

    // game
    uint256 public constant FEE = 100;

    // metadata
    string public name = "XXXXXXX";
    string public constant symbol = "XXXXXX";
    uint8 public constant decimals = 18;

    // fee whitelist
    mapping(address => bool) public whitelistFrom;
    mapping(address => bool) public whitelistTo;

    // Field
    Field public Field;

    // internal
    uint256 public extraGas;
    bool inited;

    function init(
        address _to,
        uint256 _amount
    ) external {
        // Only init once
        assert(!inited);
        inited = true;

        // Sanity checks
        assert(totalSupply == 0);
        assert(address(Field) == address(0));

        // Create Field
        Field = new Field();
        emit SetField(address(0), address(Field));

        // Init contract variables and mint
        // entire token balance
        extraGas = 15;
        emit SetExtraGas(0, extraGas);
        emit Transfer(address(0), _to, _amount);
        _setBalance(_to, _amount);
        totalSupply = _amount;
    }

    ///
    // Storage access functions
    ///

    function _toKey(address a) internal pure returns (bytes32) {
        return bytes32(uint256(a));
    }

    function _balanceOf(address _addr) internal view returns (uint256) {
        return uint256(_toKey(_addr).read(BALANCE_KEY));
    }

    function _allowance(address _addr, address _spender) internal view returns (uint256) {
        return uint256(_toKey(_addr).read(keccak256(abi.encodePacked("allowance", _spender))));
    }

    function _nonce(address _addr, uint256 _cat) internal view returns (uint256) {
        return uint256(_toKey(_addr).read(keccak256(abi.encodePacked("nonce", _cat))));
    }

    // Setters

    function _setAllowance(address _addr, address _spender, uint256 _value) internal {
        _toKey(_addr).write(keccak256(abi.encodePacked("allowance", _spender)), bytes32(_value));
    }

    function _setNonce(address _addr, uint256 _cat, uint256 _value) internal {
        _toKey(_addr).write(keccak256(abi.encodePacked("nonce", _cat)), bytes32(_value));
    }

    function _setBalance(address _addr, uint256 _balance) internal {
        _toKey(_addr).write(BALANCE_KEY, bytes32(_balance));
        Field.update(_addr, _balance);
    }

    ///
    // Internal methods
    ///

    function _isWhitelisted(address _from, address _to) internal view returns (bool) {
        return whitelistFrom[_from]||whitelistTo[_to];
    }

    function _random(address _s1, uint256 _s2, uint256 _s3, uint256 _max) internal pure returns (uint256) {
        uint256 rand = uint256(keccak256(abi.encodePacked(_s1, _s2, _s3)));
        return rand % (_max + 1);
    }

    function _pickWinner(address _from, uint256 _value) internal returns (address winner) {
        // Get order of magnitude of the tx
        uint256 magnitude = Math.orderOfMagnitude(_value);
        // Pull nonce for a given order of magnitude
        uint256 nonce = _nonce(_from, magnitude);
        _setNonce(_from, magnitude, nonce + 1);
        // pick entry from Field
        winner = Field.addressAt(_random(_from, nonce, magnitude, Field.size() - 1));
    }

    function _transferFrom(address _operator, address _from, address _to, uint256 _value, bool _payFee) internal {
        // If transfer amount is zero
        // emit event and stop execution
        if (_value == 0) {
            emit Transfer(_from, _to, 0);
            return;
        }

        // Load sender balance
        uint256 balanceFrom = _balanceOf(_from);
        require(balanceFrom >= _value, "balance not enough");

        // Check if operator is sender
        if (_from != _operator) {
            // If not, validate allowance
            uint256 allowanceFrom = _allowance(_from, _operator);
            // If allowance is not 2 ** 256 - 1, consume allowance
            if (allowanceFrom != uint(-1)) {
                // Check allowance and save new one
                require(allowanceFrom >= _value, "allowance not enough");
                _setAllowance(_from, _operator, allowanceFrom.sub(_value));
            }
        }

        // Calculate receiver balance
        // initial receive is full value
        uint256 receive = _value;
        uint256 burn = 0;
        uint256 disperse = 0;

        // Change sender balance
        _setBalance(_from, balanceFrom.sub(_value));

        // If the transaction is not whitelisted
        // or if sender requested to pay the fee
        // calculate fees
        if (_payFee || !_isWhitelisted(_from, _to)) {
            // Fee is the same for BURN and disperse
            // If we are sending value one
            // give priority to BURN
            burn = _value.divRound(FEE);
            disperse = _value == 1 ? 0 : burn;

            // Subtract fees from receiver amount
            receive = receive.sub(burn.add(disperse));

            // Burn tokens
            totalSupply = totalSupply.sub(burn);
            emit Transfer(_from, address(0), burn);

            // disperse tokens
            // Pick winner pseudo-randomly
            address winner = _pickWinner(_from, _value);
            // Transfer balance to winner
            _setBalance(winner, _balanceOf(winner).add(disperse));
            emit Winner(winner, disperse);
            emit Transfer(_from, winner, disperse);
        }

        // Sanity checks
        // no tokens where created
        assert(burn.add(disperse).add(receive) == _value);

        // Add tokens to receiver
        _setBalance(_to, _balanceOf(_to).add(receive));
        emit Transfer(_from, _to, receive);
    }

    ///
    // Dev Parameters
    ///
	
	
	function setCrowdSaleContract(address _contractAddress) onlyOwner public {
        crowdSaleContract = _contractAddress;
	}

    function setWhitelistedTo(address _addr, bool _whitelisted) external onlyOwner {
        emit WhitelistTo(_addr, _whitelisted);
        whitelistTo[_addr] = _whitelisted;
    }

    function setWhitelistedFrom(address _addr, bool _whitelisted) external onlyOwner {
        emit WhitelistFrom(_addr, _whitelisted);
        whitelistFrom[_addr] = _whitelisted;
    }

    function setName(string calldata _name) external onlyOwner {
        emit SetName(name, _name);
        name = _name;
    }

    function setExtraGas(uint256 _gas) external onlyOwner {
        emit SetExtraGas(extraGas, _gas);
        extraGas = _gas;
    }

    function setField(Field _Field) external onlyOwner {
        emit SetField(address(Field), address(_Field));
        Field = _Field;
    }

    /////
    // Field methods
    /////

    function topSize() external view returns (uint256) {
        return Field.topSize();
    }

    function FieldSize() external view returns (uint256) {
        return Field.size();
    }

    function FieldEntry(uint256 _i) external view returns (address, uint256) {
        return Field.entry(_i);
    }

    function FieldTop() external view returns (address, uint256) {
        return Field.top();
    }

    function FieldIndex(address _addr) external view returns (uint256) {
        return Field.indexOf(_addr);
    }

    function getNonce(address _addr, uint256 _cat) external view returns (uint256) {
        return _nonce(_addr, _cat);
    }

    /////
    // BASE Level
    /////

    function balanceOf(address _addr) external view returns (uint256) {
        return _balanceOf(_addr);
    }

    function allowance(address _addr, address _spender) external view returns (uint256) {
        return _allowance(_addr, _spender);
    }

    function approve(address _spender, uint256 _value) external returns (bool) {
        emit Approval(msg.sender, _spender, _value);
        _setAllowance(msg.sender, _spender, _value);
        return true;
    }

    function transfer(address _to, uint256 _value) external requestGas(extraGas) returns (bool) {
        _transferFrom(msg.sender, msg.sender, _to, _value, false);
        return true;
    }

    function transferWithFee(address _to, uint256 _value) external requestGas(extraGas) returns (bool) {
        _transferFrom(msg.sender, msg.sender, _to, _value, true);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external requestGas(extraGas) returns (bool) {
        _transferFrom(msg.sender, _from, _to, _value, false);
        return true;
    }
    
    
    function tokensSold(address _buyer, uint256 _amount) public returns (bool success) {
        require(msg.sender == crowdSaleContract);
        _transferFrom(msg.sender, msg.sender,_buyer, _amount, false);
        return true;
    
        
    }

    function transferFromWithFee(address _from, address _to, uint256 _value) external requestGas(extraGas) returns (bool) {
        _transferFrom(msg.sender, _from, _to, _value, true);
        return true;
    }
}
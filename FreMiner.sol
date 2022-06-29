// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.5.0;

import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./TransferHelper.sol";
import "./IBEP20.sol";
import "./LpWallet.sol";
import "./FreMinePool.sol";

interface IPancakePair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

contract FreMiner is ReentrancyGuard {
    using TransferHelper for address;
    using SafeMath for uint256;

    address private _freaddr = address(0xA9ef15CF0D72Bf6ae5e408967fa9A03A8e21129f);
    address private _fretrade = address(0xCeDd0A1EbC204d764d2172a7aDa0192DEEE4ACe2);
    address private _bnbtradeaddress = address(0x16b9a82891338f9bA80E2D6970FddA79D1eb0daE);
    address private _wrappedbnbaddress = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    address private _usdtaddress = address(0x55d398326f99059fF775485246999027B3197955);
    address private _destoryaddress = address(0x000000000000000000000000000000000000dEaD);

    address private _owner;
    address private _feeowner;
    uint256 private _burnVal;
    FreMinePool _minepool;
    

    mapping(uint256 => uint256[20]) internal _levelconfig; //credit level config
    uint256 _nowtotalhash;
    mapping(uint256 => uint256[1]) private _checkpoints;
    uint256 private _currentMulitiper1;
    uint256 private _currentMulitiper2;
    uint256 private _currentMulitiper3;
    uint256 private _currentMulitiper4;
    uint256 public _maxcheckpoint;
    mapping(address =>  uint256) public _lphash;
    mapping(address => mapping(address => uint256)) public _userLphash;
    mapping(address => mapping(uint256 => uint256)) public _userlevelhashtotal; // level hash in my team
    mapping(address => address) internal _parents; //Inviter
    mapping(address => UserInfo) public _userInfos;
    mapping(address => PoolInfo) _lpPools;
    mapping(address => address[]) _mychilders;
    mapping(uint256 => uint256) _pctRate;

    uint256 public lastdst = 7 days;
    mapping(address => mapping(address => uint256)) public dst;

    address[] _lpaddresses;

    uint256 public inviteSend = 3e18;
    uint256 public minTakeBack = 10e18;

    struct PoolInfo {
        LpWallet poolwallet;
        uint256 hashrate; //  The LP hashrate
        address tradeContract;
        uint256 minpct;
        uint256 maxpct;
    }

    uint256[8] _vipbuyprice = [0, 100, 300, 500, 800, 1200, 1600, 2000];

    struct UserInfo {
        uint256 selfhash; //user hash total count
        uint256 teamhash;
        uint256 userlevel; // my userlevel
        uint256 pendingreward;
        uint256 lastblock;
        uint256 lastcheckpoint;
    }

    event BindingParents(address indexed user, address inviter);
    event VipChanged(address indexed user, uint256 userlevel);
    event TradingPooladded(address indexed tradetoken);
    event UserBuied(
        address indexed tokenaddress,
        address indexed useraddress,
        uint256 amount,
        uint256 hashb
    );
    event TakedBack(address indexed tokenaddress, uint256 pct);

    constructor() {
        _owner = msg.sender;
        _feeowner = msg.sender;
    }

    function getMinerPoolAddress() public view returns (address) {
        return address(_minepool);
    }

    function setInviteSend(uint256 _inviteSend) public {
        require(msg.sender == _owner);
        inviteSend = _inviteSend;
    }

    function setMinTakeBack(uint256 _minTakeBack) public {
        require(msg.sender == _owner);
        minTakeBack = _minTakeBack;
    }

    function setPctRate(uint256 pct, uint256 rate) public {
        require(msg.sender == _owner);
        _pctRate[pct] = rate;
    }

    function setLastdst(uint256 newLastdst) public {
        require(msg.sender == _owner);
        lastdst = newLastdst;
    }

    function getHashRateByPct(uint256 pct) public view returns (uint256) {
        if (_pctRate[pct] > 0) return _pctRate[pct];

        return 100;
    }

    function getMyChilders(address user)
        public
        view
        returns (address[] memory)
    {
        return _mychilders[user];
    }

    // 初始化合约
    function InitalContract(
    ) public {
        require(msg.sender == _owner);
        _minepool = new FreMinePool(_freaddr, _owner);
        _parents[msg.sender] = address(_minepool);

        _pctRate[70] = 120;
        _pctRate[50] = 150;
        _pctRate[100] = 210;

        _levelconfig[0] = [
            100,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0
        ];
        _levelconfig[1] = [
            150,
            100,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0
        ];
        _levelconfig[2] = [
            160,
            110,
            90,
            60,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0
        ];
        _levelconfig[3] = [
            170,
            120,
            100,
            70,
            40,
            30,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0
        ];
        _levelconfig[4] = [
            180,
            130,
            110,
            80,
            40,
            30,
            20,
            10,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0
        ];
        _levelconfig[5] = [
            200,
            140,
            120,
            90,
            40,
            30,
            20,
            10,
            10,
            10,
            10,
            10,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0
        ];
        _levelconfig[6] = [
            220,
            160,
            140,
            100,
            40,
            30,
            20,
            10,
            10,
            10,
            10,
            10,
            10,
            10,
            10,
            10,
            0,
            0,
            0,
            0
        ];
        _levelconfig[7] = [
            250,
            180,
            160,
            110,
            40,
            30,
            20,
            10,
            10,
            10,
            10,
            10,
            10,
            10,
            10,
            10,
            10,
            10,
            10,
            10
        ];

        _maxcheckpoint = 1;
        _checkpoints[_maxcheckpoint][0] = block.number;

        _currentMulitiper1 = uint256(1888e18).div(28800);
        _currentMulitiper2 = uint256(18888e18).div(28800);
        _currentMulitiper3 = uint256(188888e18).div(28800);
        _currentMulitiper4 = uint256(1888888e18).div(28800);
    }

    function getCurrentCheckPoint() public view returns (uint256[1] memory) {
        return _checkpoints[_maxcheckpoint];
    }

    function getTradingPool(address lptoken)
        public
        view
        returns (PoolInfo memory)
    {
        return _lpPools[lptoken];
    }

    function fixTradingPool(
        address tokenAddress,
        address tradecontract,
        uint256 rate,
        uint256 pctmin,
        uint256 pctmax
    ) public returns (bool) {
        require(msg.sender == _owner);
        _lpPools[tokenAddress].hashrate = rate;
        _lpPools[tokenAddress].tradeContract = tradecontract;
        _lpPools[tokenAddress].minpct = pctmin;
        _lpPools[tokenAddress].maxpct = pctmax;
        return true;
    }

    function addTradingPool(
        address tokenAddress,
        address tradecontract,
        uint256 rate,
        uint256 pctmin,
        uint256 pctmax
    ) public returns (bool) {
        require(msg.sender == _owner);
        require(rate > 0, "ERROR RATE");
        require(_lpPools[tokenAddress].hashrate == 0, "LP EXISTS");

        LpWallet wallet = new LpWallet(
            tokenAddress,
            _freaddr,
            _feeowner,
            _owner
        );
        _lpPools[tokenAddress] = PoolInfo({
            poolwallet: wallet,
            hashrate: rate,
            tradeContract: tradecontract,
            minpct: pctmin,
            maxpct: pctmax
        });
        _lpaddresses.push(tokenAddress);
        emit TradingPooladded(tokenAddress);
        return true;
    }

    function getParent(address user) public view returns (address) {
        return _parents[user];
    }

    function getTotalHash() public view returns (uint256) {
        return _nowtotalhash;
    }

    function getMyLpInfo(address user, address tokenaddress)
        public
        view
        returns (uint256[3] memory)
    {
        uint256[3] memory bb;
        bb[0] = _lpPools[tokenaddress].poolwallet.getBalance(user, true);
        bb[1] = _lpPools[tokenaddress].poolwallet.getBalance(user, false);
        bb[2] = _userLphash[user][tokenaddress];
        return bb;
    }

    function getUserLevel(address user) public view returns (uint256) {
        return _userInfos[user].userlevel;
    }

    function getUserTeamHash(address user) public view returns (uint256) {
        return _userInfos[user].teamhash;
    }

    function getUserSelfHash(address user) public view returns (uint256) {
        return _userInfos[user].selfhash;
    }

    function getFeeOwner() public view returns (address) {
        return _feeowner;
    }

    function getExchangeCountOfOneUsdt(address lptoken)
        public
        view
        returns (uint256)
    {
        require(_lpPools[lptoken].tradeContract != address(0));

        if (lptoken == address(2)) //BNB
        {
            (uint112 _reserve0, uint112 _reserve1, ) = IPancakePair(
                _bnbtradeaddress
            ).getReserves();
            uint256 a = _reserve0;
            uint256 b = _reserve1;
            return b.mul(1e18).div(a);
        }

        if (lptoken == _freaddr) {
            (uint112 _reserve0, uint112 _reserve1, ) = IPancakePair(_fretrade)
                .getReserves();
            uint256 a = _reserve0;
            uint256 b = _reserve1;
            return b.mul(1e18).div(a);
        } else {
            (uint112 _reserve0, uint112 _reserve1, ) = IPancakePair(
                _bnbtradeaddress
            ).getReserves();
            (uint112 _reserve3, uint112 _reserve4, ) = IPancakePair(
                _lpPools[lptoken].tradeContract
            ).getReserves();

            uint256 balancea = _reserve0;
            uint256 balanceb = _reserve1;
            uint256 balancec = IPancakePair(_lpPools[lptoken].tradeContract)
                .token0() == lptoken
                ? _reserve3
                : _reserve4;
            uint256 balanced = IPancakePair(_lpPools[lptoken].tradeContract)
                .token0() == lptoken
                ? _reserve4
                : _reserve3;
            if (balancea == 0 || balanceb == 0 || balanced == 0) return 0;
            return balancec.mul(1e18).div(balancea.mul(balanced).div(balanceb));
        }
    }

    function buyVipPrice(address user, uint256 newlevel)
        public
        view
        returns (uint256)
    {
        if (newlevel >= 8) return 0;

        uint256 userlevel = _userInfos[user].userlevel;
        if (userlevel >= newlevel) return 0;
        uint256 costprice = _vipbuyprice[newlevel] - _vipbuyprice[userlevel];
        uint256 costcount = costprice.mul(getExchangeCountOfOneUsdt(_freaddr));
        return costcount;
    }

    function getWalletAddress(address lptoken) public view returns (address) {
        return address(_lpPools[lptoken].poolwallet);
    }

    function logCheckPoint(
        uint256 totalhashdiff,
        bool add,
        uint256 blocknumber
    ) private {
        if (add) {
            _nowtotalhash = _nowtotalhash.add(totalhashdiff);
        } else {
            _nowtotalhash = _nowtotalhash.sub(totalhashdiff);
        }
        _checkpoints[_maxcheckpoint][0] = blocknumber;
    }

    function getHashDiffOnLevelChange(address user, uint256 newlevel)
        private
        view
        returns (uint256)
    {
        uint256 hashdiff = 0;
        uint256 userlevel = _userInfos[user].userlevel;
        for (uint256 i = 0; i < 20; i++) {
            if (_userlevelhashtotal[user][i] > 0) {
                if (_levelconfig[userlevel][i] > 0) {
                    uint256 dff = _userlevelhashtotal[user][i]
                        .mul(_levelconfig[newlevel][i])
                        .sub(
                            _userlevelhashtotal[user][i].mul(
                                _levelconfig[userlevel][i]
                            )
                        );
                    dff = dff.div(1000);
                    hashdiff = hashdiff.add(dff);
                } else {
                    uint256 dff = _userlevelhashtotal[user][i]
                        .mul(_levelconfig[newlevel][i])
                        .div(1000);
                    hashdiff = hashdiff.add(dff);
                }
            }
        }
        return hashdiff;
    }

    function ChangeWithDrawPoint(
        address user,
        uint256 blocknum,
        uint256 pendingreward
    ) public {
        require(msg.sender == _owner);
        _userInfos[user].pendingreward = pendingreward;
        _userInfos[user].lastblock = blocknum;
        if (_maxcheckpoint > 0)
            _userInfos[user].lastcheckpoint = _maxcheckpoint;
    }

    function buyVip(uint256 newlevel) public nonReentrant returns (bool) {
        require(newlevel < 8);
        require(_parents[msg.sender] != address(0), "must bind parent first");
        uint256 costcount = buyVipPrice(msg.sender, newlevel);
        require(costcount > 0);
        uint256 diff = getHashDiffOnLevelChange(msg.sender, newlevel);
        if (diff > 0) {
            UserHashChanged(msg.sender, 0, diff, true, block.number);
            logCheckPoint(diff, true, block.number);
        }

        IBEP20(_freaddr).transferFrom(msg.sender, _destoryaddress, costcount);
        _burnVal = _burnVal.add(costcount);
        _userInfos[msg.sender].userlevel = newlevel;
        emit VipChanged(msg.sender, newlevel);
        return true;
    }

    function withdraw(address user, uint256 amount) public nonReentrant returns (bool) {
        require(msg.sender == _owner);
        _minepool.MineOut(user, amount, 0);
        return true;
    }

    function bindParent(address parent) public nonReentrant {
        require(_parents[msg.sender] == address(0), "Already bind");
        require(parent != address(0), "ERROR parent");
        require(parent != msg.sender, "error parent");
        require(_parents[parent] != address(0));
        _parents[msg.sender] = parent;
        _mychilders[parent].push(msg.sender);

        indeposit(msg.sender, inviteSend);
        // _minepool.MineOut(msg.sender, inviteSend, 0);
        emit BindingParents(msg.sender, parent);
    }

    function SetParentByAdmin(address user, address parent) public {
        require(_parents[user] == address(0), "Already bind");
        require(msg.sender == _owner);
        _parents[user] = parent;
        _mychilders[parent].push(user);
    }

    function getUserLasCheckPoint(address useraddress)
        public
        view
        returns (uint256)
    {
        return _userInfos[useraddress].lastcheckpoint;
    }

    function getPendingCoin(address user) public view returns (uint256) {
        if (_userInfos[user].lastblock == 0) {
            return 0;
        }
        UserInfo memory info = _userInfos[user];
        uint256 total = info.pendingreward;
        uint256 mytotalhash = info.selfhash.add(info.teamhash);
        if (mytotalhash == 0) return total;
        uint256 lastblock = info.lastblock;

        uint256 cm;
        if (_nowtotalhash <= 1e23) {
            cm = _currentMulitiper1;
        } else if (_nowtotalhash > 1e23 && _nowtotalhash <= 1e24) {
            cm = _currentMulitiper2;
        } else if (_nowtotalhash > 1e24 && _nowtotalhash <= 1e25) {
            cm = _currentMulitiper3;
        } else {
            cm = _currentMulitiper4;
        }

        if (_maxcheckpoint > 0) {
            if (info.lastcheckpoint > 0) {
                for (
                    uint256 i = info.lastcheckpoint + 1;
                    i <= _maxcheckpoint;
                    i++
                ) {
                    uint256 blockk = _checkpoints[i][0];
                    if (blockk <= lastblock) {
                        continue;
                    }
                    uint256 get = blockk
                        .sub(lastblock)
                        .mul(cm)
                        .mul(mytotalhash)
                        .div(_nowtotalhash);
                    total = total.add(get);
                    lastblock = blockk;
                }
            }

            if (lastblock < block.number && lastblock > 0) {
                uint256 blockcount = block.number.sub(lastblock);
                if (_nowtotalhash > 0) {
                    uint256 get = blockcount.mul(cm).mul(mytotalhash).div(
                        _nowtotalhash
                    );
                    total = total.add(get);
                }
            }
        }
        return total;
    }

    function UserHashChanged(
        address user,
        uint256 selfhash,
        uint256 teamhash,
        bool add,
        uint256 blocknum
    ) private {
        uint256 dash = getPendingCoin(user);
        UserInfo memory info = _userInfos[user];
        info.pendingreward = dash;
        info.lastblock = blocknum;
        if (_maxcheckpoint > 0) {
            info.lastcheckpoint = _maxcheckpoint;
        }
        if (selfhash > 0) {
            if (add) {
                info.selfhash = info.selfhash.add(selfhash);
            } else info.selfhash = info.selfhash.sub(selfhash);
        }
        if (teamhash > 0) {
            if (add) {
                info.teamhash = info.teamhash.add(teamhash);
            } else {
                if (info.teamhash > teamhash)
                    info.teamhash = info.teamhash.sub(teamhash);
                else info.teamhash = 0;
            }
        }
        _userInfos[user] = info;
    }

    function WithDrawCredit() public nonReentrant returns (bool) {
        uint256 amount = getPendingCoin(msg.sender);
        if (amount < 100) return true;

        _userInfos[msg.sender].pendingreward = 0;
        _userInfos[msg.sender].lastblock = block.number;
        if (_maxcheckpoint > 0)
            _userInfos[msg.sender].lastcheckpoint = _maxcheckpoint;
        uint256 fee = amount.div(100);
        _minepool.MineOut(msg.sender, amount.sub(fee), fee);
        return true;
    }

    function isTakeBack(address tokenAddress, address userAddress, uint256 pct) public view returns (bool) {
        uint256 balancea = _lpPools[tokenAddress].poolwallet.getBalance(
            userAddress,
            true
        );
        uint256 balanceb = _lpPools[tokenAddress].poolwallet.getBalance(
            userAddress,
            false
        );

        uint256 amounta = balancea.mul(pct).div(1000000);
        uint256 amountb = balanceb.mul(pct).div(1000000);

        bool res;
        if (tokenAddress == _freaddr) {
            if (amounta >= minTakeBack) res = true;
        } else {
            if (amountb >= minTakeBack) res = true;
        }

        return res;
    }

    function TakeBack(address tokenAddress, uint256 pct)
        public
        nonReentrant
        returns (bool)
    {
        require(block.timestamp - dst[tokenAddress][msg.sender] >= lastdst, "less time.");
        require(pct >= 10000 && pct <= 1000000);
        uint256 balancea = _lpPools[tokenAddress].poolwallet.getBalance(
            msg.sender,
            true
        );
        uint256 balanceb = _lpPools[tokenAddress].poolwallet.getBalance(
            msg.sender,
            false
        );

        uint256 totalhash = _userLphash[msg.sender][tokenAddress];

        uint256 amounta = balancea.mul(pct).div(1000000);
        uint256 amountb = balanceb.mul(pct).div(1000000);

        if (tokenAddress == _freaddr) {
            require(amounta >= minTakeBack, "less fre token.");
        } else {
            require(amountb >= minTakeBack, "less fre token.");
        }

        uint256 decreasehash = _userLphash[msg.sender][tokenAddress]
            .mul(pct)
            .div(1000000);

        _userLphash[msg.sender][tokenAddress] = totalhash.sub(decreasehash);
        _lphash[tokenAddress] -= decreasehash;

        address parent = msg.sender;
        uint256 dthash = 0;
        for (uint256 i = 0; i < 20; i++) {
            parent = _parents[parent];
            if (parent == address(0)) break;

            _userlevelhashtotal[parent][i] = _userlevelhashtotal[parent][i].sub(
                decreasehash
            );
            uint256 parentlevel = _userInfos[parent].userlevel;
            uint256 pdechash = decreasehash
                .mul(_levelconfig[parentlevel][i])
                .div(1000);
            if (pdechash > 0) {
                dthash = dthash.add(pdechash);
                UserHashChanged(parent, 0, pdechash, false, block.number);
            }
        }
        UserHashChanged(msg.sender, decreasehash, 0, false, block.number);
        logCheckPoint(decreasehash.add(dthash), false, block.number);
        _lpPools[tokenAddress].poolwallet.TakeBack(
            msg.sender,
            amounta,
            amountb
        );
        if (tokenAddress == address(2)) {
            uint256 fee2 = amounta.div(100);
            (bool success, ) = msg.sender.call{value: amounta.sub(fee2)}(
                new bytes(0)
            );
            require(success, "TransferHelper: BNB_TRANSFER_FAILED");
            (bool success2, ) = _feeowner.call{value: fee2}(new bytes(0));
            require(success2, "TransferHelper: BNB_TRANSFER_FAILED");
            if (amountb >= 100) {
                uint256 fee = amountb.div(100); //Destory 1%
                IBEP20(_freaddr).transfer(msg.sender, amountb.sub(fee));
                IBEP20(_freaddr).transfer(_destoryaddress, fee);
                _burnVal = _burnVal.add(fee);
            } else {
                IBEP20(_freaddr).transfer(msg.sender, amountb);
            }
        }
        emit TakedBack(tokenAddress, pct);
        return true;
    }

    function changeOwner(address owner) public returns (bool) {
        require(msg.sender == _owner);
        _owner = owner;
        _feeowner = owner;
        return true;
    }

    function changeFeeOwner(address feeowner) public returns (bool) {
        require(msg.sender == _owner);
        _feeowner = feeowner;
        return true;
    }

    function burnVal() public view returns (uint256) {
        return _burnVal;
    }

    function getPower(
        address tokenAddress,
        uint256 amount,
        uint256 lpscale
    ) public view returns (uint256) {
        uint256 hashb = amount.mul(1e20).div(lpscale).div(
            getExchangeCountOfOneUsdt(tokenAddress)
        );
        return hashb;
    }

    function getLpPayfre(
        address tokenAddress,
        uint256 amount,
        uint256 lpscale
    ) public view returns (uint256) {
        require(lpscale <= 100);
        uint256 hashb = amount.mul(1e20).div(lpscale).div(
            getExchangeCountOfOneUsdt(tokenAddress)
        );
        uint256 costabc = hashb
            .mul(getExchangeCountOfOneUsdt(_freaddr))
            .mul(100 - lpscale)
            .div(1e20);
        return costabc;
    }

    function deposit(
        address tokenAddress,
        uint256 amount,
        uint256 dppct
    ) public payable nonReentrant returns (bool) {
        require(_parents[msg.sender] != address(0), "must bind parent first");
        if (tokenAddress == address(2)) {
            amount = msg.value;
        }
        require(dppct >= _lpPools[tokenAddress].minpct, "Pct1");
        require(dppct <= _lpPools[tokenAddress].maxpct, "Pct2");
        uint256 price = getExchangeCountOfOneUsdt(tokenAddress);
        uint256 freprice = getExchangeCountOfOneUsdt(_freaddr);
        uint256 hashb = amount.mul(1e20).div(dppct).div(price);
        uint256 costfre = hashb.mul(freprice).mul(100 - dppct).div(1e20);
        hashb = hashb.mul(getHashRateByPct(dppct)).div(100);
        uint256 abcbalance = IBEP20(_freaddr).balanceOf(msg.sender);

        if (abcbalance < costfre) {
            require(tokenAddress != address(2), "fre balance");
            amount = amount.mul(abcbalance).div(costfre);
            hashb = amount.mul(abcbalance).div(costfre);
            costfre = abcbalance;
        }
        if (tokenAddress == address(2)) {
            if (costfre > 0)
                _freaddr.safeTransferFrom(msg.sender, address(this), costfre);
        } else {
            tokenAddress.safeTransferFrom(
                msg.sender,
                address(_lpPools[tokenAddress].poolwallet),
                amount
            );
            if (costfre > 0)
                _freaddr.safeTransferFrom(
                    msg.sender,
                    address(_lpPools[tokenAddress].poolwallet),
                    costfre
                );
        }

        _lpPools[tokenAddress].poolwallet.addBalance(
            msg.sender,
            amount,
            costfre
        );

        _userLphash[msg.sender][tokenAddress] = _userLphash[msg.sender][
            tokenAddress
        ].add(hashb);
        _lphash[tokenAddress] += hashb;

        address parent = msg.sender;
        uint256 dhash = 0;

        for (uint256 i = 0; i < 20; i++) {
            parent = _parents[parent];
            if (parent == address(0)) break;

            _userlevelhashtotal[parent][i] = _userlevelhashtotal[parent][i].add(
                hashb
            );
            uint256 parentlevel = _userInfos[parent].userlevel;
            uint256 levelconfig = _levelconfig[parentlevel][i];
            if (levelconfig > 0) {
                uint256 addhash = hashb.mul(levelconfig).div(1000);
                if (addhash > 0) {
                    dhash = dhash.add(addhash);
                    UserHashChanged(parent, 0, addhash, true, block.number);
                }
            }
        }

        dst[tokenAddress][msg.sender] = block.timestamp;

        UserHashChanged(msg.sender, hashb, 0, true, block.number);
        logCheckPoint(hashb.add(dhash), true, block.number);
        emit UserBuied(tokenAddress, msg.sender, amount, hashb);
        return true;
    }

    function indeposit(address user, uint256 amount) internal returns (bool) {
        uint256 freprice = getExchangeCountOfOneUsdt(_freaddr);
        uint256 hashb = amount.mul(1e20).div(100).div(freprice);
        hashb = hashb.mul(getHashRateByPct(100)).div(100);

        _freaddr.safeTransfer(
            address(_lpPools[_freaddr].poolwallet),
            amount
        );

        _lpPools[_freaddr].poolwallet.addBalance(
            user,
            amount,
            0
        );

        _userLphash[user][_freaddr] = _userLphash[user][
            _freaddr
        ].add(hashb);
        _lphash[_freaddr] += hashb;

        address parent = user;
        uint256 dhash = 0;

        for (uint256 i = 0; i < 20; i++) {
            parent = _parents[parent];
            if (parent == address(0)) break;

            _userlevelhashtotal[parent][i] = _userlevelhashtotal[parent][i].add(
                hashb
            );
            uint256 parentlevel = _userInfos[parent].userlevel;
            uint256 levelconfig = _levelconfig[parentlevel][i];
            if (levelconfig > 0) {
                uint256 addhash = hashb.mul(levelconfig).div(1000);
                if (addhash > 0) {
                    dhash = dhash.add(addhash);
                    UserHashChanged(parent, 0, addhash, true, block.number);
                }
            }
        }

        dst[_freaddr][user] = block.timestamp;

        UserHashChanged(user, hashb, 0, true, block.number);
        logCheckPoint(hashb.add(dhash), true, block.number);
        emit UserBuied(_freaddr, user, amount, hashb);
        return true;
    }

}

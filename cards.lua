#!/usr/bin/env lua

require "lunit"
module("cards", lunit.testcase, package.seeall)

local Card = {}
function Card:new(suit, value)
    local o = {}
    o.suit  = suit
    o.value = value
    setmetatable(o, self)
    self.__index = self
    return o
end

function Card:say()
    local names = { "A", "2", "3", "4", "5", "6", "7", "8", "9", "T", "J", "Q", "K" }
    return names[self.value] .. self.suit
end
-- class Card

local Hand = {}
function Hand:new()
    local o = {}
    o.cards = {}
    o.rank = 1
    o.hidden = 1
    --setmetatable(o, self)
    setmetatable(o, Hand.mt)
    self.__index = self
    return o
end

Hand.mt = { __index = Hand }

Hand.mt.__lt = function(a, b)
    return (a:score() < b:score())
end

Hand.mt.__le = function(a, b)
    return (a:score() <= b:score())
end

Hand.mt.__eq = function(a, b)
    return (a:score() == b:score())
end

function Hand:fill()
    for _,suit in ipairs({ "H", "D", "C", "S" }) do
        for val=1, 13 do
            local card = Card:new(suit, val)
            self:push(card)
        end
    end
end

function Hand:say()
    local str = ""
    for _,card in ipairs(self.cards) do
        str = str .. card:say() .. " "
    end
    return str
end

function Hand:push(card)
    return table.insert(self.cards, card)
end

function Hand:pop()
    return table.remove(self.cards, #self.cards)
end

function Hand:shuffle()
    math.randomseed(os.time())
    local new = Hand:new()
    for i=1, #self.cards do
        local r = math.random(1, #self.cards)
        new:push(self.cards[r])
        table.remove(self.cards, r)
    end
    self.cards = new.cards
    new.cards = nil
end

function Hand:pick(str)
    for i,card in ipairs(self.cards) do
        if card:say() == str then
            return table.remove(self.cards, i)
        end
    end
    return nil
end

function Hand:refresh_rank()
    if is_royal(self) then
        self.rank = 10
    elseif is_straight_flush(self) then
        self.rank = 9
    elseif is_four(self) then
        self.rank = 8
    elseif is_fullhouse(self) then
        self.rank = 7
    elseif is_flush(self) then
        self.rank = 6
    elseif is_straight(self) then
        self.rank = 5
    elseif is_three(self) then
        self.rank = 4
    elseif is_twopairs(self) then
        self.rank = 3
    elseif is_pair(self) then
        self.rank = 2
    else
        self.rank = 1
    end
end

function Hand:identify()
    local names = {
        "high",
        "pairs",
        "two pairs",
        "three of a kind",
        "straight",
        "flush",
        "full house",
        "four of a kind",
        "straight flush",
        "royal straight flush",
    }
    local vnames = { "A", "2", "3", "4", "5", "6", "7", "8", "9", "T", "J", "Q", "K" }
    self:refresh_rank()
    local val = 2
    if self.rank == 1 then
        for i,card in ipairs(self.cards) do
            if card.value > val then
                val = card.value
            elseif card.value == 1 then
                return vnames[1] .. " high"
            end
        end
        names[1] = vnames[val] .. " high"
    end
    return names[self.rank]
end

function Hand:score()
    self:refresh_rank()
    local mul = { 4096, 1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096 }
    local score = 0
    for i,card in ipairs(self.cards) do
        score = score + mul[card.value]
    end
    return score + self.rank * 4096
end
-- class Hand

function is_flush(hand)
    local suit = hand.cards[1].suit
    local match = 0
    for _,card in ipairs(hand.cards) do
        if card.suit == suit then
            match = match + 1
        end
    end
    return match == 5
end

function is_straight(hand)
    local tab = {}
    for i,card in ipairs(hand.cards) do
        tab[card.value] = 1
        if card.value == 1 then tab[14] = 1 end
    end
    match = 0
    for i=1, 14 do
        if tab[i] == 1 then
            match = match + 1
            if match == 5 then return true end
        else
            match = 0
        end
    end
    return false
end

function is_straight_flush(hand)
    return is_straight(hand) and is_flush(hand)
end

function is_royal(hand)
    function has_KA()
        local count = 0
        for i,card in ipairs(hand.cards) do
            if card.value == 1 or card.value == 13 then
                count = count + 1
            end
        end
        return count == 2
    end
    return is_straight_flush(hand) and has_KA()
end

function is_fullhouse(hand)
    return is_three(hand) and is_pair(hand)
end

function is_same(hand, amount)
    function create_tab()
        local t = {}
        for i=1, 14 do t[i] = 0 end
        return t
    end
    local tab = create_tab()

    for i,card in ipairs(hand.cards) do
        tab[card.value] = tab[card.value] + 1
        if card.value == 1 then tab[14] = 1 end
    end
    for i=1, #tab do
        if tab[i] == amount then
            return true
        end
    end
    return false
end

function is_pair(hand)
    return is_same(hand, 2)
end

function is_twopairs(hand)
    if not is_same(hand, 2) then return false end

    function create_tab()
        local t = {}
        for i=1, 14 do t[i] = 0 end
        return t
    end
    local tab = create_tab()

    for i,card in ipairs(hand.cards) do
        tab[card.value] = tab[card.value] + 1
        if card.value == 1 then tab[14] = 1 end
    end
    local pair = 0
    for i=1, #tab do
        if tab[i] == 2 then
            pair = pair + 1
        end
    end
    return pair == 2
end

function is_three(hand)
    return is_same(hand, 3)
end

function is_four(hand)
    return is_same(hand, 4)
end

-- Tests
function test_card()
    local card = Card:new("H", 7)
    assert_equal("7H", card:say())
end

function test_deck()
    local deck = Hand:new()
    deck:fill()
    local card = deck:pop()
    assert_equal("KS", card:say())
    local kort = deck:pop()
    assert_equal("QS", kort:say())
end

function test_shuffle()
    local deck = Hand:new()
    deck:fill()
    local sdeck = Hand:new()
    sdeck:fill()
    sdeck:shuffle()
    assert_not_equal(deck:say(), sdeck:say())
end

function test_deal()
    local deck = Hand:new()
    deck:fill()
    deck:shuffle()
    local p1 = Hand:new()
    local p2 = Hand:new()
    for i=1, 5 do
        p1:push(deck:pop())
        p2:push(deck:pop())
    end
    assert(string.len(p1:say()) > 8)
    assert(string.len(p2:say()) > 8)
end

function test_pick_card()
    local d = Hand:new()
    d:fill()
    local ts = d:pick("TS")
    assert_equal("TS", ts:say())
    ts = d:pick("TS")
    assert_equal(nil, ts)
end

function test_flush()
    local deck = Hand:new()
    deck:fill()
    local p1 = Hand:new()
    for i,name in ipairs({ "2H", "KH", "QH", "JH", "TH" }) do
        p1:push(deck:pick(name))
    end
    assert_true(is_flush(p1))
    assert_equal("flush", p1:identify())

    p1 = Hand:new()
    for i,name in ipairs({ "2H", "KH", "QH", "JS", "TH" }) do
        p1:push(deck:pick(name))
    end
    assert_false(is_flush(p1))
    assert_not_equal("flush", p1:identify())
end

function test_straight()
    local deck = Hand:new()
    deck:fill()
    local p1 = Hand:new()
    for i,name in ipairs({ "AH", "5S", "4D", "3C", "2H" }) do
        p1:push(deck:pick(name))
    end
    assert_true(is_straight(p1))
    assert_equal("straight", p1:identify())

    deck = Hand:new()
    deck:fill()
    p1 = Hand:new()
    for i,name in ipairs({ "AH", "5S", "8D", "3C", "2H" }) do
        p1:push(deck:pick(name))
    end
    assert_false(is_straight(p1))
    assert_not_equal("straight", p1:identify())

    deck = Hand:new()
    deck:fill()
    p1 = Hand:new()
    for i,name in ipairs({ "AH", "KS", "TD", "JC", "QH" }) do
        p1:push(deck:pick(name))
    end
    assert_true(is_straight(p1))
    assert_equal("straight", p1:identify())
end

function test_straight_flush()
    local deck = Hand:new()
    deck:fill()
    local p1 = Hand:new()
    for i,name in ipairs({ "AH", "5H", "4H", "3H", "2H" }) do
        p1:push(deck:pick(name))
    end
    assert_true(is_straight_flush(p1))
    assert_equal("straight flush", p1:identify())

    deck = Hand:new()
    deck:fill()
    p1 = Hand:new()
    for i,name in ipairs({ "9S", "KS", "QS", "TS", "JS" }) do
        p1:push(deck:pick(name))
    end
    assert_true(is_straight_flush(p1))
    assert_equal("straight flush", p1:identify())
end

function test_royal()
    local deck = Hand:new()
    deck:fill()
    local p1 = Hand:new()
    for i,name in ipairs({ "AH", "KH", "TH", "QH", "JH" }) do
        p1:push(deck:pick(name))
    end
    assert_true(is_royal(p1))
    assert_equal("royal straight flush", p1:identify())

    deck = Hand:new()
    deck:fill()
    p1 = Hand:new()
    for i,name in ipairs({ "AD", "KD", "TD", "QD", "JD" }) do
        p1:push(deck:pick(name))
    end
    assert_true(is_royal(p1))
    assert_equal("royal straight flush", p1:identify())
end

function test_fullhouse()
    local deck = Hand:new()
    deck:fill()
    local p1 = Hand:new()
    for i,name in ipairs({ "AH", "AC", "AS", "4H", "4C" }) do
        p1:push(deck:pick(name))
    end
    assert_true(is_fullhouse(p1))
    assert_equal("full house", p1:identify())
end

function test_pair()
    local deck = Hand:new()
    deck:fill()
    local p1 = Hand:new()
    for i,name in ipairs({ "4H", "8C", "KS", "4C", "3C" }) do
        p1:push(deck:pick(name))
    end
    assert_true(is_pair(p1))
    assert_equal("pairs", p1:identify())
end

function test_twopairs()
    local deck = Hand:new()
    deck:fill()
    local p1 = Hand:new()
    for i,name in ipairs({ "4H", "KC", "KS", "4C", "3C" }) do
        p1:push(deck:pick(name))
    end
    assert_true(is_twopairs(p1))
    assert_equal("two pairs", p1:identify())
end

function test_three()
    local deck = Hand:new()
    deck:fill()
    local p1 = Hand:new()
    for i,name in ipairs({ "4H", "8C", "KS", "4C", "4S" }) do
        p1:push(deck:pick(name))
    end
    assert_true(is_three(p1))
    assert_equal("three of a kind", p1:identify())
end

function test_four()
    local deck = Hand:new()
    deck:fill()
    local p1 = Hand:new()
    for i,name in ipairs({ "4H", "4D", "KS", "4C", "4S" }) do
        p1:push(deck:pick(name))
    end
    assert_true(is_four(p1))
    assert_equal("four of a kind", p1:identify())
end

function test_high()
    local deck = Hand:new()
    deck:fill()
    local p1 = Hand:new()
    for i,name in ipairs({ "AH", "TS", "9H", "4C", "3C" }) do
        p1:push(deck:pick(name))
    end
    assert_equal("A high", p1:identify())
end

function test_score()
    local deck = Hand:new()
    deck:fill()
    local p1 = Hand:new()
    for i,name in ipairs({ "AH", "2S", "3H", "4C", "6C" }) do
        p1:push(deck:pick(name))
    end
    local p2 = Hand:new()
    for i,name in ipairs({ "KC", "TD", "QC", "JD", "8S" }) do
        p2:push(deck:pick(name))
    end
    assert(p1 > p2)
    assert(p2 < p1)
end

function test_winner()
    local deck = Hand:new()
    deck:fill()
    local p1 = Hand:new()
    for i,name in ipairs(ace_high) do
        p1:push(deck:pick(name))
    end
    local p2 = Hand:new()
    for i,name in ipairs(four) do
        p2:push(deck:pick(name))
    end
    assert(p2 > p1)
    assert_false(p2 < p1)
    assert_false(p2 == p1)
end

function test_equal()
    local deck = Hand:new()
    deck:fill()
    local p1 = Hand:new()
    for i,name in ipairs(ace_high) do
        p1:push(deck:pick(name))
    end
    local p2 = Hand:new()
    for i,name in ipairs(ace_high2) do
        p2:push(deck:pick(name))
    end
    assert(p1 == p2)
    assert_false(p1 < p2)
    assert_false(p1 > p2)
end

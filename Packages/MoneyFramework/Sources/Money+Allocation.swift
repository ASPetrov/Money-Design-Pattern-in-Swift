extension Money {

    /// Maximum number of results produced by either checked allocation method.
    public static var maximumAllocationRecipients: Int { 1_000_000 } // swiftlint:disable:this identifier_name

    /// Allocates equally, assigning any remaining minor units in input order.
    public func allocate(recipientCount: Int) throws -> [Money] {
        guard
            (1 ... Self.maximumAllocationRecipients).contains(recipientCount)
        else {
            throw ArithmeticError.invalidRecipientCount
        }
        let units = try checkedMinorUnits()
        let (share, remainder) =
            units.magnitude.quotientAndRemainder(dividingBy: UInt(recipientCount))
        let isNegative = units < 0
        let standard = try moneyShare(share, isNegative: isNegative)
        var shares = Array(repeating: standard, count: recipientCount)
        if remainder > 0 {
            let extra = try moneyShare(share + 1, isNegative: isNegative)
            for index in 0 ..< Int(remainder) {
                shares[index] = extra
            }
        }
        return shares
    }

    /// Allocates by nonnegative weights and assigns the remainder to positive weights in input order.
    public func allocate(ratios: [Int]) throws -> [Money] {
        guard
            (1 ... Self.maximumAllocationRecipients).contains(ratios.count)
        else {
            throw ArithmeticError.invalidRecipientCount
        }
        let totalWeight = try checkedTotalWeight(of: ratios)
        return try allocate(count: ratios.count, totalWeight: totalWeight) {
            UInt(ratios[$0])
        }
    }

    /// For validated inputs. Use allocate(recipientCount:) to handle errors.
    public func allocate(_ n: Int) -> [Money] {
        requireValidMoneyOperation("equal allocation") {
            try allocate(recipientCount: n)
        }
    }

    /// For validated inputs. Use allocate(ratios:) to handle errors.
    public func allocate(_ ratios: [Int]) -> [Money] {
        requireValidMoneyOperation("weighted allocation") {
            try allocate(ratios: ratios)
        }
    }

    private func checkedTotalWeight(of ratios: [Int]) throws -> UInt {
        var totalWeight: UInt = 0
        for ratio in ratios {
            guard let weight = UInt(exactly: ratio) else {
                throw ArithmeticError.invalidRatios
            }
            let (sum, overflow) = totalWeight.addingReportingOverflow(weight)
            guard !overflow else {
                throw ArithmeticError.totalWeightOutOfRange
            }
            totalWeight = sum
        }
        guard totalWeight > 0 else {
            throw ArithmeticError.invalidRatios
        }
        return totalWeight
    }

    private func allocate(
        count: Int,
        totalWeight: UInt,
        weightAt: (Int) -> UInt
    ) throws -> [Money] {
        let units = try checkedMinorUnits()
        let magnitude = units.magnitude
        var remaining = magnitude
        var shares: [UInt] = []
        shares.reserveCapacity(count)

        for index in 0 ..< count {
            let product = magnitude.multipliedFullWidth(by: weightAt(index))
            let share = totalWeight.dividingFullWidth(product).quotient
            shares.append(share)
            remaining -= share
        }
        for index in shares.indices where remaining > 0 && weightAt(index) > 0 {
            shares[index] += 1
            remaining -= 1
        }

        return try shares.map { try moneyShare($0, isNegative: units < 0) }
    }

    private func moneyShare(_ share: UInt, isNegative: Bool) throws -> Money {
        // The magnitude can be one larger than Int.max only for a negative amount.
        let signedShare =
            isNegative ? Int(bitPattern: 0 &- share) : Int(share)
        let value = try Amount(
            minorUnits: signedShare,
            scale: currency.minorUnits
        )
        return try result(amount: value.decimalValue)
    }
}

enum MoneyOperation {

    static func require<Value>(
        _ operation: StaticString,
        _ body: () throws -> Value
    ) -> Value {
        require(operation) {
            Result(catching: body)
        }
    }

    static func require<Value, Failure: Error>(
        _ operation: StaticString,
        _ body: () -> Result<Value, Failure>
    ) -> Value {
        switch body() {
        case let .success(value):
            return value
        case let .failure(error):
            preconditionFailure("Money \(operation) failed: \(error)")
        }
    }
}

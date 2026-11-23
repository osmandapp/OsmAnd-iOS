final class CheckDateRowBehaviour: DefaultPoiAdditionalRowBehaviour {
    override func applyCustomRules(params: PoiRowParams) {
        super.applyCustomRules(params: params)
        params.builder.text = CheckDateFormatter.format(params.value) ?? params.value
    }
}

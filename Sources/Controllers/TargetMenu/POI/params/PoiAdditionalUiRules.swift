//
//  PoiAdditionalUiRules.swift
//  OsmAnd
//
//  Created by Max Kojin on 03/02/26.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

final class PoiAdditionalUiRules: NSObject {
    
    static let shared = PoiAdditionalUiRules()
    
    var rules = [PoiAdditionalUiRule]()
    var rulesByKey = [String: PoiAdditionalUiRule]()
    
    private override init() {
        rules = [PoiAdditionalUiRule]()
        rulesByKey = [String: PoiAdditionalUiRule]()
        
        let collectionTimes = PoiAdditionalUiRule(key: COLLECTION_TIMES_TAG)
        collectionTimes.customIconName = "ic_action_time"
        collectionTimes.isNeedLinks = false
        rules.append(collectionTimes)
        rulesByKey[COLLECTION_TIMES_TAG] = collectionTimes
        
        let serviceTimes = PoiAdditionalUiRule(key: SERVICE_TIMES_TAG)
        serviceTimes.customIconName = "ic_action_time"
        serviceTimes.isNeedLinks = false
        rules.append(serviceTimes)
        rulesByKey[SERVICE_TIMES_TAG] = serviceTimes
        
        let openingHours = PoiAdditionalUiRule(key: OPENING_HOURS_TAG)
        openingHours.customIconName = "ic_action_time"
        openingHours.customTextPrefix = localizedString("opening_hours")
        openingHours.isNeedLinks = false
        openingHours.behavior = OpeningHoursRowBehavior()
        rules.append(openingHours)
        rulesByKey[OPENING_HOURS_TAG] = openingHours

        let phone = PoiAdditionalUiRule(key: PHONE_TAG)
        phone.customIconName = "ic_phone_number"
        phone.customTextPrefix = localizedString("phone")
        phone.isPhoneNumber = true
        rules.append(phone)
        rulesByKey[PHONE_TAG] = phone
        
        let mobile = PoiAdditionalUiRule(key: MOBILE_TAG)
        mobile.customIconName = "ic_phone_number"
        mobile.customTextPrefix = localizedString("poi_mobile")
        mobile.isPhoneNumber = true
        rules.append(mobile)
        rulesByKey[MOBILE_TAG] = mobile
        
        let website = PoiAdditionalUiRule(key: WEBSITE_TAG)
        website.customIconName = "ic_world_globe_dark"
        website.isUrl = true
        rules.append(website)
        rulesByKey[WEBSITE_TAG] = website
        
        let url = PoiAdditionalUiRule(key: URL_TAG)
        url.customIconName = "ic_world_globe_dark"
        url.isUrl = true
        rules.append(url)
        rulesByKey[URL_TAG] = url
        
        let cuisine = PoiAdditionalUiRule(key: CUISINE_TAG)
        cuisine.customIconName = "ic_cuisine"
        cuisine.customTextPrefix = localizedString("poi_cuisine")
        cuisine.behavior = CuisineRowBehavior()
        rules.append(cuisine)
        rulesByKey[CUISINE_TAG] = cuisine
        
        let description = PoiAdditionalUiRule(key: DESCRIPTION_TAG)
        description.customIconName = "ic_description"
        description.checkBaseKey = true
        description.checkKeyOnContains = true
        rules.append(description)
        rulesByKey[DESCRIPTION_TAG] = description
        
        let wiki = PoiAdditionalUiRule(key: WIKIPEDIA_TAG)
        wiki.customIconName = "ic_custom_wikipedia"
        wiki.customTextPrefix = localizedString("download_wikipedia_maps")
        wiki.isWikipedia = true
        wiki.checkBaseKey = false
        wiki.checkKeyOnContains = true
        wiki.behavior = WikipediaRowBehavior()
        rules.append(wiki)
        rulesByKey[WIKIPEDIA_TAG] = wiki
        
        let houseName = PoiAdditionalUiRule(key: "addr:housename")
        houseName.customIconName = "ic_custom_poi_name"
        houseName.checkBaseKey = false
        rules.append(houseName)
        rulesByKey["addr:housename"] = houseName
        
        let rapidName = PoiAdditionalUiRule(key: "whitewater:rapid_name")
        rapidName.customIconName = "ic_custom_poi_name"
        rapidName.checkBaseKey = false
        rules.append(rapidName)
        rulesByKey["whitewater:rapid_name"] = rapidName
        
        let operatorName = PoiAdditionalUiRule(key: OPERATOR_TAG)
        operatorName.customIconName = "ic_custom_poi_brand"
        operatorName.customTextPrefix = localizedString("poi_operator")
        operatorName.checkBaseKey = true
        rules.append(operatorName)
        rulesByKey[OPERATOR_TAG] = operatorName
        
        let brandName = PoiAdditionalUiRule(key: BRAND_TAG)
        brandName.customIconName = "ic_custom_poi_brand"
        brandName.customTextPrefix = localizedString("poi_brand")
        brandName.checkBaseKey = true
        rules.append(brandName)
        rulesByKey[BRAND_TAG] = brandName
        
        let population = PoiAdditionalUiRule(key: POPULATION_TAG)
        population.isNeedLinks = false
        population.behavior = PopulationRowBehaviour()
        rules.append(population)
        rulesByKey[POPULATION_TAG] = population
        
        let internetAccess = PoiAdditionalUiRule(key: "internet_access_fee_yes")
        internetAccess.customIconName = "ic_custom_internet_access_fee"
        rules.append(internetAccess)
        rulesByKey["internet_access_fee_yes"] = internetAccess
        
        let instagram = PoiAdditionalUiRule(key: "instagram")
        instagram.customIconName = "ic_custom_logo_instagram"
        rules.append(instagram)
        rulesByKey["instagram"] = instagram
        
        let height = PoiAdditionalUiRule(key: HEIGHT_TAG)
        height.customTextPrefix = localizedString("shared_string_height")
        height.isNeedLinks = false
        height.behavior = MetricRowBehaviour()
        rules.append(height)
        rulesByKey[HEIGHT_TAG] = height
        
        let width = PoiAdditionalUiRule(key: WIDTH_TAG)
        width.customTextPrefix = localizedString("shared_string_width")
        width.isNeedLinks = false
        width.behavior = MetricRowBehaviour()
        rules.append(width)
        rulesByKey[WIDTH_TAG] = width
        
        let depth = PoiAdditionalUiRule(key: "depth")
        depth.behavior = MetricRowBehaviour()
        rules.append(depth)
        rulesByKey["depth"] = depth
        
        let seamarkHeight = PoiAdditionalUiRule(key: "seamark_height")
        seamarkHeight.behavior = MetricRowBehaviour()
        rules.append(seamarkHeight)
        rulesByKey["seamark_height"] = seamarkHeight
        
        let distance = PoiAdditionalUiRule(key: DISTANCE_TAG)
        distance.customTextPrefix = localizedString("shared_string_distance")
        distance.isNeedLinks = false
        distance.behavior = DistanceRowBehaviour()
        rules.append(distance)
        rulesByKey[DISTANCE_TAG] = distance
        
        let capacity = PoiAdditionalUiRule(key: "capacity")
        capacity.behavior = LiquidCapacityRowBehaviour()
        rules.append(capacity)
        rulesByKey["capacity"] = capacity
        
        let maxweight = PoiAdditionalUiRule(key: "maxweight")
        maxweight.behavior = MaxWeightRowBehaviour()
        rules.append(maxweight)
        rulesByKey["maxweight"] = maxweight
        
        let students = PoiAdditionalUiRule(key: "students")
        students.behavior = CapacityRowBehaviour()
        rules.append(students)
        rulesByKey["students"] = students
        
        let spots = PoiAdditionalUiRule(key: "spots")
        spots.behavior = CapacityRowBehaviour()
        rules.append(spots)
        rulesByKey["spots"] = spots
        
        let seats = PoiAdditionalUiRule(key: "seats")
        seats.behavior = CapacityRowBehaviour()
        rules.append(seats)
        rulesByKey["seats"] = seats
        
        let usMapsRecreationArea = PoiAdditionalUiRule(key: "us_maps_recreation_area")
        usMapsRecreationArea.behavior = UsMapsRecreationAreaRowBehaviour()
        rules.append(usMapsRecreationArea)
        rulesByKey["us_maps_recreation_area"] = usMapsRecreationArea
        
        let ele = PoiAdditionalUiRule(key: "ele")
        ele.behavior = EleRowBehaviour()
        rules.append(ele)
        rulesByKey["ele"] = ele
    }
    
    func findRule(key: String) -> PoiAdditionalUiRule {
        let baseKey = key.components(separatedBy: ":")[0]
        
        // First, try exact match
        if let value = rulesByKey[key] {
            return value
        }
        
        for rule in rules {
            // Decide whether to use baseKey or full key based on the rule
            let keyToSearch = rule.checkBaseKey ? baseKey : key
            
            // If the rule requires "contains" match
            if rule.checkKeyOnContains {
                if keyToSearch.contains(rule.key) {
                    return rule
                }
            } else {
                // Else check for exact match
                if keyToSearch == rule.key {
                    return rule
                }
            }
        }
        
        // If no match found, return a default rule with the given key
        return PoiAdditionalUiRule(key: key)
    }
}

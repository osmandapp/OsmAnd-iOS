
// IMPLEMENTED (X) or MISSING ( ) FEATURES, (N/A) if not needed in this language:
//
// (X) Basic navigation prompts: route (re)calculated (with distance and time support), turns, roundabouts, u-turns, straight/follow, arrival
// (X) Announce nearby point names (destination / intermediate / GPX waypoint / favorites / POI)
// (X) Attention prompts: SPEED_CAMERA; SPEED_LIMIT; BORDER_CONTROL; RAILWAY; TRAFFIC_CALMING; TOLL_BOOTH; STOP; PEDESTRIAN; MAXIMUM; TUNNEL
// (X) Other prompts: gps lost, off route, back to route
// (X) Street name and prepositions (onto / on / to) and street destination (toward) support
// (X) Distance unit support (meters / feet / yard)
// (N/A) Special grammar: (please specify which)

var metricConst;
var dictionary = {};
//// STRINGS
////////////////////////////////////////////////////////////////
// ROUTE CALCULATED
dictionary["route_is1.ogg"] = "De berekende afstand is ";
dictionary["route_is2.ogg"] = "lang";
dictionary["route_calculate.ogg"] = "Afstand is opnieuw berekend";
dictionary["distance.ogg"] = ", de nieuwe afstand is ";

// LEFT/RIGHT
dictionary["prepare.ogg"] = "Verder op ";
// Verder op should officially be spelled as verderop but is not pronounced correctly
// by tts voices when spelled that way. Please leave it like this.
dictionary["after.ogg"] = "Na ";

dictionary["left.ogg"] = "links afslaan";
dictionary["left_sh.ogg"] = "scherpe bocht naar links";
dictionary["left_sl.ogg"] = "links afbuigen";
dictionary["right.ogg"] = "rechts afslaan";
dictionary["right_sh.ogg"] = "scherpe bocht naar rechts";
dictionary["right_sl.ogg"] = "rechts afbuigen";
dictionary["left_keep.ogg"] = "links aanhouden";
dictionary["right_keep.ogg"] = "rechts aanhouden";
dictionary["left_bear.ogg"] = "links aanhouden";    // in English the same as left_keep, may be different in other languages
dictionary["right_bear.ogg"] = "rechts aanhouden";  // in English the same as right_keep, may be different in other languages

// U-TURNS
dictionary["prepare_make_uturn.ogg"] = "Keer om na ";
dictionary["make_uturn1.ogg"] = "omkeren ";
dictionary["make_uturn2.ogg"] = "keer nu om";
dictionary["make_uturn_wp.ogg"] = "Indien mogelijk, nu omkeren";

// ROUNDABOUTS
dictionary["prepare_roundabout.ogg"] = "Neem de rotonde na ";
dictionary["roundabout.ogg"] = "de rotonde oprijden en neem dan de ";
dictionary["then.ogg"] = "dan ";
dictionary["and.ogg"] = " en ";
dictionary["take.ogg"] = "Neem de ";
dictionary["exit.ogg"] = "afslag";

dictionary["1st.ogg"] = "eerste ";
dictionary["2nd.ogg"] = "tweede ";
dictionary["3rd.ogg"] = "derde ";
dictionary["4th.ogg"] = "vierde ";
dictionary["5th.ogg"] = "vijfde ";
dictionary["6th.ogg"] = "zesde ";
dictionary["7th.ogg"] = "zevende ";
dictionary["8th.ogg"] = "achtste ";
dictionary["9th.ogg"] = "negende  ";
dictionary["10th.ogg"] = "tiende ";
dictionary["11th.ogg"] = "elfde ";
dictionary["12th.ogg"] = "twaalfde ";
dictionary["13th.ogg"] = "dertiende ";
dictionary["14th.ogg"] = "viertiende ";
dictionary["15th.ogg"] = "vijftiende ";
dictionary["16th.ogg"] = "zestiende ";
dictionary["17th.ogg"] = "zeventiende ";

// STRAIGHT/FOLLOW
dictionary["go_ahead.ogg"] = "Deze weg blijven volgen";
dictionary["follow1.ogg"] = "De weg  ";
dictionary["follow2.ogg"] = "volgen";

// ARRIVE
dictionary["and_arrive_destination.ogg"] = "dan heb je je bestemming ";
dictionary["reached_destination.ogg"] = "je hebt je Bestemming ";
dictionary["and_arrive_intermediate.ogg"] = "en dan heb je je routepunt ";
dictionary["reached_intermediate.ogg"] = "je hebt je routepunt ";
dictionary["reached.ogg"] = "bereikt  ";

// NEARBY POINTS
dictionary["and_arrive_waypoint.ogg"] = "en dan heb je je GPX routepunt ";
dictionary["reached_waypoint.ogg"] = "je hebt je GPX routepunt ";
dictionary["and_arrive_favorite.ogg"] = "en dan heb je je favoriet ";
dictionary["reached_favorite.ogg"] = "je hebt je favoriet ";
dictionary["and_arrive_poi.ogg"] = "en dan heb je je POI ";
dictionary["reached_poi.ogg"] = "je hebt je POI ";

// ATTENTION
//dictionary["exceed_limit.ogg"] = "je overschrijdt de maximumsnelheid ";
dictionary["exceed_limit.ogg"] = "maximumsnelheid ";
dictionary["attention.ogg"] = "let op , ";
dictionary["speed_camera.ogg"] = "snelheidscontrole";
dictionary["border_control.ogg"] = "grenscontrole";
dictionary["railroad_crossing.ogg"] = "spoorweg overgang";
dictionary["traffic_calming.ogg"] = "verkeersdrempel";
dictionary["toll_booth.ogg"] = "tol poort";
// de spatie is nodig voor een betere uitspraak
dictionary["stop.ogg"] = "stop teken";
dictionary["pedestrian_crosswalk.ogg"] = "zebra";
dictionary["tunnel.ogg"] = "tunnel";

// OTHER PROMPTS
dictionary["location_lost.ogg"] = "G P S  signaal verloren";
dictionary["location_recovered.ogg"] = "g p s signaal hersteld";
dictionary["off_route.ogg"] = "je bent afgeweken van de route vanaf ";
dictionary["back_on_route.ogg"] = "je bent weer op de route";

// STREET NAME PREPOSITIONS
dictionary["onto.ogg"] = "naar ";
dictionary["toward.ogg"] = "richting  ";

// DISTANCE UNIT SUPPORT
dictionary["meters.ogg"] = "meter";
dictionary["around_1_kilometer.ogg"] = "ongeveer een kilometer";
dictionary["around.ogg"] = "ongeveer ";
dictionary["kilometers.ogg"] = "kilometer";

dictionary["feet.ogg"] = "voet ";
dictionary["1_tenth_of_a_mile.ogg"] = "een tiende mijl";
dictionary["tenths_of_a_mile.ogg"] = "tiende mijl";
dictionary["around_1_mile.ogg"] = "ongeveer een mijl";
dictionary["miles.ogg"] = "mijlen";

dictionary["yards.ogg"] = "yards";

// TIME SUPPORT
dictionary["time.ogg"] = ", tijd tot bestemming ";
dictionary["1_hour.ogg"] = "een uur ";
dictionary["hours.ogg"] = "uur ";
dictionary["less_a_minute.ogg"] = "minder dan een minuut";
dictionary["1_minute.ogg"] = "een minuut";
dictionary["minutes.ogg"] = "minuten";


//// COMMAND BUILDING / WORD ORDER
////////////////////////////////////////////////////////////////
function setMetricConst(metrics) {
	metricConst = metrics;
}

function route_new_calc(dist, timeVal) {
	return dictionary["route_is1"] + " " + distance(dist) + " " + dictionary["time"] + " " + time(timeVal) + ". ";
}

function distance(dist) {
	switch (metricConst) {
		case "km-m":
			if (dist < 17 ) {
				return Math.round(dist).toString() + " " + dictionary["meters"];
			} else if (dist < 100) {
				return Math.round((2*dist/100.0)*50).toString() + " " + dictionary["meters"];
			} else if (dist < 1000) {
				return Math.round((2*dist/100.0)*50).toString() + " " + dictionary["meters"];
			} else if (dist < 1500) {
				return dictionary["around_1_kilometer"];
			} else if (dist < 10000) {
				return dictionary["around"] + " " + Math.round(dist/1000.0).toString() + " " + dictionary["kilometers"];
			} else {
				return Math.round(dist/1000.0).toString() + " " + dictionary["kilometers"];
			}
			break;
		case "mi-f":
			if (dist < 160) {
				return Math.round((2*dist/100.0/0.3048)*50).toString(); + " " + dictionary["feet"];
			} else if (dist < 241) {
				return dictionary["1_tenth_of_a_mile"];
			} else if (dist < 1529) {
				return Math.round(dist/161.0).toString() + " " + dictionary["tenths_of_a_mile"];
			} else if (dist < 2414) {
				return dictionary["around_1_mile"];
			} else if (dist < 16093) {
				return dictionary["around"] + " " + Math.round(dist/1609.3).toString() + " " + dictionary["miles"];
			} else {
				return Math.round(dist/1609.3).toString() + " " + dictionary["miles"];
			}
			break;
		case "mi-m":
			if (dist < 17) {
				return Math.round(dist).toString() + " " + dictionary["meters"];
			} else if (dist < 100) {
				return Math.round((2*dist/100.0)*50).toString() + " " + dictionary["meters"];
			} else if (dist < 1300) {
				return Math.round(dist/1609.3).toString() + " " + dictionary["meters"]; 
			} else if (dist < 2414) {
				return dictionary["around_1_mile"];
			} else if (dist < 16093) {
				return dictionary["around"] + " " + Math.round(dist/1609.3).toString() + " " + dictionary["miles"];
			} else {
				return Math.round(dist/1609.3).toString() + " " + dictionary["miles"];
			}
			break;
		case "mi/y":
			if (dist < 17) {
				return Math.round(dist/0.9144).toString() + " " + dictionary["yards"];
			} else if (dist < 100) {
				return Math.round((dist/10.0/0.9144)*10).toString() + " " + dictionary["yards"];
			} else if (dist < 1300) {
				return Math.round((2*dist/100.0/0.9144)*50).toString() + " " + dictionary["yards"]; 
			} else if (dist < 2414) {
				return dictionary["around_1_mile"];
			} else if (dist < 16093) {
				return dictionary["around"] + " " + Math.round(dist/1609.3).toString() + " " + dictionary["miles"];
			} else {
				return Math.round(dist/1609.3).toString() + " " + dictionary["miles"];
			}
			break;
	}
}

function time(seconds) {
	var minutes = Math.round(seconds/60.0);
	if (seconds < 30) {
		return dictionary["less_a_minute"];
	} else if (minutes % 60 == 1) {
		return dictionary["1_minute"];
	} else if (minutes < 60.0) {
		return minutes.toString() + " " + dictionary["minutes"];
	} else if (minutes < 120) {
		return dictionary["1_hour"];
	} else  {
		return Math.round(minutes/60).toString() + " " + dictionary["hours"];
	}
}

function route_recalc(dist, seconds) {
	return dictionary["route_calculate"] + " " + distance(dist) + " " + dictionary["time"] + " " + time(seconds) + ". ";
}

function go_ahead(dist, streetName) {
	if (dist == -1) {
		return dictionary["go_ahead"];
	} else {
		return dictionary["follow1"] + " " + distance(dist) + " " + dictionary["follow2"] + " " + turn_street(streetName);
	}
	
// go_ahead(Dist, Street) -- ["follow", D | Sgen] :- distance(Dist) -- D, follow_street(Street, Sgen).
// follow_street("", []).
// follow_street(voice(["","",""],_), []).
// follow_street(voice(["", "", D], _), ["to", D]) :- tts.
// follow_street(Street, ["on", SName]) :- tts, Street = voice([R, S, _],[R, S, _]), assemble_street_name(Street, SName).
// follow_street(Street, ["on", SName]) :- tts, Street = voice([R, "", _],[R, _, _]), assemble_street_name(Street, SName).
// follow_street(Street, ["to", SName]) :- tts, not(Street = voice([R, S, _],[R, S, _])), assemble_street_name(Street, SName).
}

function follow_street(streetName) {
	if ((streetName["toDest"] === "" && streetName["toStreetName"] === "" && streetName["toRef"] === "") || Object.keys(streetName).length == 0) {
		return "";
	} else if (streetName["toStreetName"] === "" && streetName["toRef"] === "") {
		return dictionary["to"] + " " + streetName["toDest"];
	} else if (streetName["toRef"] === streetName["fromRef"] && streetName["toStreetName"] === streetName["fromStreetName"] || 
			(streetName["toRef"] == streetName["fromRef"] && streetName["toStreetName"] == "")) {
		return dictionary["on"] + " " + assemble_street_name(streetName);
	} else if (!(streetName["toRef"] === streetName["fromRef"] && streetName["toStreetName"] === streetName["fromStreetName"])) {
		return dictionary["to"] + " " + assemble_street_name(streetName);
	}
}

function turn(turnType, dist, streetName) {
	if (dist == -1) {
		return getTurnType(turnType) + " " + turn_street(streetName);
	} else {
		return dictionary["after"] + " " + distance(dist) + " " + getTurnType(turnType) + " " + turn_street(streetName); 
	}
	// turn(Turn, Dist, Street) -- ["in", D, M | Sgen] :- distance(Dist) -- D, turn(Turn, M), turn_street(Street, Sgen).
// turn(Turn, Street) -- [M | Sgen] :- turn(Turn, M), turn_street(Street, Sgen).
}

function  getTurnType(turnType) {
	// turn("left", ).
// turn("left_sh", ["left_sh"]).
// turn("left_sl", ["left_sl"]).
// turn("right", ["right"]).
// turn("right_sh", ["right_sh"]).
// turn("right_sl", ["right_sl"]).
// turn("left_keep", ["left_keep"]).
// turn("right_keep", ["right_keep"]).
// // Note: turn("left_keep"/"right_keep",[]) is a turn type aiding lane selection, while bear_left()/bear_right() is triggered as brief "turn-after-next" preparation sounding always after a "..., then...". In some languages turn(l/r_keep) may not differ from bear_l/r:
	switch (turnType) {
		case "left":
			return dictionary["left"];
			break;
		case "left_sh":
			return dictionary["left_sh"];
			break;
		case "left_sl":
			return dictionary["left_sl"];
			break;
		case "right":
			return dictionary["right"];
			break;
		case "right_sh":
			return dictionary["right_sh"];
			break;
		case "right_sl":
			return dictionary["right_sl"];
			break;
		case "left_keep":
			return dictionary["left_keep"];
			break;
		case "right_keep":
			return dictionary["right_keep"];
			break;
	}
}

function then() {
	// then -- ["then"].
	return dictionary["then"];
}

function roundabout(dist, angle, exit, streetName) {
	// roundabout(Dist, _Angle, Exit, Street) -- ["in", D, "roundabout", "and", "take", E, "exit" | Sgen] :- distance(Dist) -- D, nth(Exit, E), turn_street(Street, Sgen).
// roundabout(_Angle, Exit, Street) -- ["take", E, "exit" | Sgen] :- nth(Exit, E), turn_street(Street, Sgen).
	if (dist == -1) {
		return dictionary["take"] + " " + nth(exit) + " " + dictionary["exit"] + " " + turn_street(streetName);
	} else {
		return dictionary["after"] + " " + distance(dist) + " " + dictionary["roundabout"] + " " + nth(exit) + " " + dictionary["exit"] + " " + turn_street(streetName);
	}

}

function turn_street(streetName) {
	// turn_street("", []).
// turn_street(voice(["","",""],_), []).
// turn_street(voice(["", "", D], _), ["toward", D]) :- tts.
// turn_street(Street, ["on", SName]) :- tts, Street = voice([R, S, _],[R, S, _]), assemble_street_name(Street, SName).
// turn_street(Street, ["on", SName]) :- tts, Street = voice([R, "", _],[R, _, _]), assemble_street_name(Street, SName).
// turn_street(Street, ["onto", SName]) :- tts, not(Street = voice([R, S, _],[R, S, _])), assemble_street_name(Street, SName).
	if ((streetName["toDest"] === "" && streetName["toStreetName"] === "" && streetName["toRef"] === "") || Object.keys(streetName).length == 0) {
		return "";
	} else if (streetName["toStreetName"] === "" && streetName["toRef"] === "") {
		return dictionary["toward"] + " " + streetName["toDest"];
	} else if (streetName["toRef"] === streetName["fromRef"] && streetName["toStreetName"] === streetName["fromStreetName"]) {
		return dictionary["onto"] + " " + assemble_street_name(streetName);
	} else if ((streetName["toRef"] === streetName["fromRef"] && streetName["toStreetName"] === streetName["fromStreetName"]) 
		|| (streetName["toStreetName"] === "" && streetName["toRef"] === streetName["fromRef"])) {
		return dictionary["onto"] + " " + assemble_street_name(streetName);
	} else if (!(streetName["toRef"] === streetName["fromRef"] && streetName["toStreetName"] === streetName["fromStreetName"])) {
		return dictionary["onto"] + " " + assemble_street_name(streetName);
	}
	return "";
}

function assemble_street_name(streetName) {
	// // assemble_street_name(voice([Ref, Name, Dest], [_CurrentRef, _CurrentName, _CurrentDest]), _).
// // assemble_street_name(voice(["", Name, _], _), Name). // not necessary
// // Next 2 lines for Name taking precedence over Dest...
// //assemble_street_name(voice([Ref, "", Dest], _), [C1, "toward", Dest]) :- atom_concat(Ref, " ", C1).
// //assemble_street_name(voice([Ref, Name, _], _), Concat) :- atom_concat(Ref, " ", C1), atom_concat(C1, Name, Concat).
// // ...or next 3 lines for Dest taking precedence over Name
// assemble_street_name(voice([Ref, Name, ""], _), Concat) :- atom_concat(Ref, " ", C1), atom_concat(C1, Name, Concat).
// assemble_street_name(voice(["", Name, Dest], _), [C1, "toward", Dest]) :- atom_concat(Name, " ", C1).
// assemble_street_name(voice([Ref, _, Dest], _), [C1, "toward", Dest]) :- atom_concat(Ref, " ", C1).
	if (streetName["toDest"] === "") {
		return streetName["toRef"] + " " + streetName["toStreetName"];
	} else if (streetName["toRef"] === "") {
		return streetName["toStreetName"] + dictionary["toward"] + streetName["toDest"];
	} else if (streetName["toRef"] != "") {
		return streetName["toRef"] + dictionary["onto"] + streetName["toDest"];
	}
}

function nth(exit) {
	switch (exit) {
		case (1):
			return dictionary["1st"];
		case (2):
			return dictionary["2nd"];
		case (3):
			return dictionary["3rd"];
		case (4):
			return dictionary["4th"];
		case (5):
			return dictionary["5th"];
		case (6):
			return dictionary["6th"];
		case (7):
			return dictionary["7th"];
		case (8):
			return dictionary["8th"];
		case (9):
			return dictionary["9th"];
		case (10):
			return dictionary["10th"];
		case (11):
			return dictionary["11th"];
		case (12):
			return dictionary["12th"];
		case (13):
			return dictionary["13th"];
		case (14):
			return dictionary["14th"];
		case (15):
			return dictionary["15th"];
		case (16):
			return dictionary["16th"];
		case (17):
			return dictionary["17th"];
	}
}

function make_ut(dist, streetName) {
	// make_ut(Dist, Street) --  ["in", D, "make_uturn" | Sgen] :- distance(Dist) -- D, turn_street(Street, Sgen).
// make_ut(Street) -- ["make_uturn" | Sgen] :- turn_street(Street, Sgen).
	if (dist == -1) {
		return dictionary["make_uturn2"] + " " + turn_street(streetName);
	} else {
		return dictionary["after"] + " " + distance(dist) + " " + dictionary["make_uturn1"] + " " + turn_street(streetName);
	}
}

// bear_left(_Street) -- ["left_bear"].
// bear_right(_Street) -- ["right_bear"].
function bear_left(streetName) {
	return dictionary["left_bear"];
}

function bear_right(streetName) {
	return dictionary["right_bear"];
}

function prepare_make_ut(dist, streetName) {
	// prepare_make_ut(Dist, Street) -- ["after", D, "make_uturn" | Sgen] :- distance(Dist) -- D, turn_street(Street, Sgen).
	return dictionary["prepare_make_ut"] + " " + distance(dist);
}

function prepare_turn(turnType, dist, streetName) {
	// prepare_turn(Turn, Dist, Street) -- ["after", D, M | Sgen] :- distance(Dist) -- D, turn(Turn, M), turn_street(Street, Sgen).
	return dictionary["after"] + " " + distance(dist) + " " + getTurnType(turnType) + " " + turn_street(streetName);
}

function prepare_roundabout(dist, exit, streetName) {
// prepare_roundabout(Dist, _Exit, _Street) -- ["after", D , "prepare_roundabout"] :- distance(Dist) -- D.
	return dictionary["prepare_roundabout"] + " " + distance(dist); 
}

// reached_destination(D) -- ["reached_destination"|Ds] :- name(D, Ds).

// reached_intermediate(D) -- ["reached_intermediate"|Ds] :- name(D, Ds).

// and_arrive_waypoint(D) -- ["and_arrive_waypoint"|Ds] :- name(D, Ds).
// reached_waypoint(D) -- ["reached_waypoint"|Ds] :- name(D, Ds).
// and_arrive_favorite(D) -- ["and_arrive_favorite"|Ds] :- name(D, Ds).
// reached_favorite(D) -- ["reached_favorite"|Ds] :- name(D, Ds).
// and_arrive_poi(D) -- ["and_arrive_poi"|Ds] :- name(D, Ds).
// reached_poi(D) -- ["reached_poi"|Ds] :- name(D, Ds).

// location_lost -- ["location_lost"].
// location_recovered -- ["location_recovered"].
// off_route(Dist) -- ["off_route", D] :- distance(Dist) -- D.
// back_on_route -- ["back_on_route"].
function and_arrive_destination(dest) {
	return dictionary["and_arrive_destination"] + " " + dest;
}

function and_arrive_intermediate(dest) {
	// and_arrive_intermediate(D) -- ["and_arrive_intermediate"|Ds] :- name(D, Ds).
	return dictionary["and_arrive_intermediate"] + " " + dest;
}

function and_arrive_waypoint(dest) {
	return dictionary["and_arrive_waypoint"] + " " + dest;
}

function and_arrive_favorite(dest) {
	return dictionary["and_arrive_favorite"] + " " + dest;
}

function and_arrive_poi(dest) {
	return dictionary["and_arrive_poi"] + " " + dest;
}

function reached_destination(dest) {
	return dictionary["reached_destination"] + " " + dest;
}

function reached_waypoint(dest) {
	return dictionary["reached_waypoint"] + " " + dest;
}

function reached_intermediate(dest) {
	return dictionary["reached_intermediate"] + " " + dest;
}

function reached_favorite(dest) {
	return dictionary["reached_favorite"] + " " + dest;
}

function reached_poi(dest) {
	return dictionary["reached_poi"] + " " + dest;
}

function location_lost() {
	return dictionary["location_lost"];
}

function location_recovered() {
	return dictionary["location_recovered"];
}

function off_route(dist) {
	return dictionary["off_route"] + " " + distance(dist);
}

function back_on_route() {
	return dictionary["back_on_route"];
}

function make_ut_wp() {
	// make_ut_wp -- ["make_uturn_wp"].
	return dictionary["make_ut_wp"];
}


// name(D, [D]) :- tts.
// name(_D, []) :- not(tts).

// // TRAFFIC WARNINGS
function speed_alarm(maxSpeed, speed) {
	return dictionary["exceed_limit"] + " " + maxSpeed.toString();
}

function attention(type) {
	return dictionary["attention"] + " " + getAttentionString(type);
}

function getAttentionString(type) {
	switch (type) {
		case "SPEED_CAMERA":
			return dictionary["speed_camera"];
			break;
		case "SPEED_LIMIT":
			return "";
			break
		case "BORDER_CONTROL":
			return dictionary["border_control"];
			break;
		case "RAILWAY":
			return dictionary["railroad_crossing"];
			break;
		case "TRAFFIC_CALMING":
			return dictionary["traffic_calming"];
			break;
		case "TOLL_BOOTH":
			return dictionary["toll_booth"];
			break;
		case "STOP":
			return dictionary["stop"];
			break;
		case "PEDESTRIAN":
			return dictionary["pedestrian_crosswalk"];
			break;
		case "MAXIMUM":
			return "";
			break;
		case "TUNNEL":
			return dictionary["tunnel"];
			break;
		default:
			return "";
			break;
	}
}
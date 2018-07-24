
var dictionary = {};
var metricConst;

//// STRINGS
////////////////////////////////////////////////////////////////
// ROUTE CALCULATED

dictionary["route_is1"] = "Die berechnete Strecke ist ";
dictionary["route_is2"] = "lang ";
dictionary["route_calculate"] = "Route neu berechnet";
dictionary["distance"] = ", Die Entfernung beträgt ";

// LEFT/RIGHT
dictionary["prepare"] = "Demnächst ";  // Demnächst sounds better then Vorbereiten zum
dictionary["after"] = "nach ";

dictionary["left"] = "links abbiegen";
dictionary["left_sh"] = "scharf links abbiegen";
dictionary["left_sl"] = "leicht links abbiegen";
dictionary["right"] = "rechts abbiegen";
dictionary["right_sh"] = "scharf rechts abbiegen";
dictionary["right_sl"] = "leicht rechts abbiegen";
dictionary["left_keep"] = "links halten";
dictionary["right_keep"] = "rechts halten";
dictionary["left_bear"] = "links halten";    // in English the same as left_keep, may be different in other languages
dictionary["right_bear"] = "rechts halten";  // in English the same as right_keep, may be different in other languages

// U-TURNS
dictionary["make_uturn1"] = "wenden";
dictionary["make_uturn2"] = "Bitte wenden";
dictionary["make_uturn_wp"] = "Wenn möglich, bitte wenden";

// ROUNDABOUTS
dictionary["prepare_roundabout"] = "einbiegen in Kreisverkehr";
dictionary["roundabout"] = "in den Kreisverkehr einfahren, ";
dictionary["then"] = ", dann ";
dictionary["and"] = "und ";
dictionary["take"] = "nehmen Sie die ";
dictionary["exit"] = "Ausfahrt";

dictionary["1st"] = "erste ";
dictionary["2nd"] = "zweite ";
dictionary["3rd"] = "dritte ";
dictionary["4th"] = "vierte ";
dictionary["5th"] = "fünfte ";
dictionary["6th"] = "sechste ";
dictionary["7th"] = "siebte ";
dictionary["8th"] = "achte ";
dictionary["9th"] = "neunte ";
dictionary["10th"] = "zehnte ";
dictionary["11th"] = "elfte ";
dictionary["12th"] = "zwölfte ";
dictionary["13th"] = "dreizehnte ";
dictionary["14th"] = "vierzehnte ";
dictionary["15th"] = "fünfzehnte ";
dictionary["16th"] = "sechzehnte ";
dictionary["17th"] = "siebzehnte ";

// STRAIGHT/FOLLOW
dictionary["go_ahead"] = "Weiter geradeaus";
dictionary["follow1"] = "Dem Strassenverlauf ";
dictionary["follow2"] = "folgen";

// ARRIVE
dictionary["and_arrive_destination"] = ", dann haben Sie Ihr Ziel ";
dictionary["reached_destination"] = "Ziel ";
dictionary["and_arrive_intermediate"] = ", dann haben Sie Ihr Zwischenziel ";
dictionary["reached_intermediate"] = "Zwischenziel ";
dictionary["reached"] = "erreicht";

// NEARBY POINTS
dictionary["and_arrive_waypoint"] = ", dann passieren Sie Wegpunkt ";
dictionary["reached_waypoint"] = "Sie passieren Wegpunkt ";
dictionary["and_arrive_favorite"] = ", dann passieren Sie Favorit ";
dictionary["reached_favorite"] = "Sie passieren Favorit ";
dictionary["and_arrive_poi"] = ", dann passieren Sie P O I ";
dictionary["reached_poi"] = "Sie passieren P O I ";

// ATTENTION
//dictionary["exceed_limit"] = "Sie überschreiten die Höchstgeschwindigkeit ";
dictionary["exceed_limit"] = "Tempolimit ";
dictionary["attention"] = "Achtung, ";
dictionary["speed_camera"] = "Geschwindigkeitskontrolle";
dictionary["border_control"] = "Grenzkontrolle";
dictionary["railroad_crossing"] = "Bahnübergang";
dictionary["traffic_calming"] = "Verkehrsberuhigung";
dictionary["toll_booth"] = "Mautstelle";
dictionary["stop"] = "Stoppschild";
dictionary["pedestrian_crosswalk"] = "Fusgängerübergang";
dictionary["tunnel"] = "Tunnel";

// OTHER PROMPTS
dictionary["location_lost"] = "GPS Signal verloren"   // maybe change to "tschie pie es"; because of pronounciation
dictionary["location_recovered"] = "GPS Signal gefunden"  // maybe change to "tschie pie es"; because of pronounciation
dictionary["off_route"] = "Sie weichen von der Route ab seit "  // possibly "Sie verlassen die Route seit ";
dictionary["back_on_route"] = "Sie sind zurück auf der Route";

// STREET NAME PREPOSITIONS
dictionary["onto"] = "auf "  // possibly "Richtung";, better grammar, but is also misleading is some cases
dictionary["on"] = "auf "    // is used if you turn together with your current street, i.e. street name does not change. "mit " or "entlang" are possible alternatives, "auf" seems to be adequate in most instances. "über"; is wrong here.
dictionary["to"] = "bis ";
dictionary["toward"] = "Richtung " // "zu "; gives wrong results in many cases

// DISTANCE UNIT SUPPORT
dictionary["meters_nominativ"] = "Meter";
dictionary["meters_dativ"] = "Metern";
dictionary["around_1_kilometer_nominativ"] = "zirka einen Kilometer";
dictionary["around_1_kilometer_dativ"] = "zirka einem Kilometer";
dictionary["around"] = "zirka ";
dictionary["kilometers_nominativ"] = "Kilometer";
dictionary["kilometers_dativ"] = "Kilometern";

dictionary["feet_nominativ"] = "Fuss";
dictionary["feet_dativ"] = "Fuss";
dictionary["1_tenth_of_a_mile_nominativ"] = "eine Zehntel Meile";
dictionary["1_tenth_of_a_mile_dativ"] = "einer Zehntel Meile";
dictionary["tenths_of_a_mile_nominativ"] = "Zehntel Meilen";
dictionary["tenths_of_a_mile_dativ"] = "Zehntel Meilen";
dictionary["around_1_mile_nominativ"] = "zirka eine Meile";
dictionary["around_1_mile_dativ"] = "zirka einer Meile";
dictionary["miles_nominativ"] = "Meilen";
dictionary["miles_dativ"] = "Meilen";

dictionary["yards_nominativ"] = "Yards";
dictionary["yards_dativ"] = "Yards";

// TIME SUPPORT
dictionary["time"] = ", Zeit ";
dictionary["1_hour"] = "eine Stunde ";
dictionary["hours"] = "Stunden ";
dictionary["less_a_minute"] = "unter einer Minute";
dictionary["1_minute"] = "eine Minute";
dictionary["minutes"] = "Minuten";

dictionary["die"] = "die";
dictionary["den"] = "den";
dictionary["zur"] = "zur";
dictionary["zum"] = "zum";


//// COMMAND BUILDING / WORD ORDER
////////////////////////////////////////////////////////////////
function setMetricConst(metrics) {
	metricConst = metrics;
}

	
function isFeminine(streetName) {
	var endings = ["strasse","straße","bahn","chaussee","gasse","zeile","allee","tangente","spange","0","1","2","3","4","5","6","7","8","9"];
	for (str in endings) {
		if (streetName["toRef"].endsWith(str) || streetName["toStreetName"].endsWith(str)) {
			return true;
		}
	}
	return false;
}

function isMasculine(streetName) {
	var endings = ["weg","ring","damm","platz","markt","steig","pfad"];
	for (str in endings) {
		if (streetName["toStreetName"].endsWith(str)) {
			return true;
		}
	}
	return false;

}

function route_new_calc(dist, timeVal) {
	// route_new_calc(Dist, Time) -- ['route_is1', D, 'route_is2', ', ', 'time', T, '. '] :- distance(Dist, nominativ) -- D, time(Time) -- T.
	return dictionary["route_is1"] + " " + distance(dist, "nominativ") + " " + dictionary["route_is2"] + " " + dictionary["time"] + " " + time(timeVal) + ". ";
}

function distance(dist, declension) {

	switch (metricConst) {
		case "km-m":
			if (dist < 17 ) {
				return Math.round(dist).toString() + " " + dictionary["meters_" + declension];
			} else if (dist < 100) {
				return Math.round((2*dist/100.0)*50).toString() + " " + dictionary["meters_" + declension];
			} else if (dist < 1000) {
				return Math.round((2*dist/100.0)*50).toString() + " " + dictionary["meters_" + declension];
			} else if (dist < 1500) {
				return dictionary["around_1_kilometer_" + declension];
			} else if (dist < 10000) {
				return dictionary["around"] + " " + Math.round(dist/1000.0).toString() + " " + dictionary["kilometers_" + declension];
			} else {
				return Math.round(dist/1000.0).toString() + " " + dictionary["kilometers_" + declension];
			}
			break;
		case "mi-f":
			if (dist < 160) {
				return Math.round((2*dist/100.0/0.3048)*50).toString(); + " " + dictionary["feet_" + declension];
			} else if (dist < 241) {
				return dictionary["1_tenth_of_a_mile_" + declension];
			} else if (dist < 1529) {
				return Math.round(dist/161.0).toString() + " " + dictionary["tenths_of_a_mile_" + declension];
			} else if (dist < 2414) {
				return dictionary["around_1_mile_" + declension];
			} else if (dist < 16093) {
				return dictionary["around"] + " " + Math.round(dist/1609.3).toString() + " " + dictionary["miles_" + declension];
			} else {
				return Math.round(dist/1609.3).toString() + " " + dictionary["miles_" + declension];
			}
			break;
		case "mi-m":
			if (dist < 17) {
				return Math.round(dist).toString() + " " + dictionary["meters_" + declension];
			} else if (dist < 100) {
				return Math.round((2*dist/100.0)*50).toString() + " " + dictionary["meters_" + declension];
			} else if (dist < 1300) {
				return Math.round(dist/1609.3).toString() + " " + dictionary["meters_" + declension]; 
			} else if (dist < 2414) {
				return dictionary["around_1_mile_" + declension];
			} else if (dist < 16093) {
				return dictionary["around"] + " " + Math.round(dist/1609.3).toString() + " " + dictionary["miles_" + declension];
			} else {
				return Math.round(dist/1609.3).toString() + " " + dictionary["miles_" + declension];
			}
			break;
		case "mi/y":
			if (dist < 17) {
				return Math.round(dist/0.9144).toString() + " " + dictionary["yards_" + declension];
			} else if (dist < 100) {
				return Math.round((dist/10.0/0.9144)*10).toString() + " " + dictionary["yards_" + declension];
			} else if (dist < 1300) {
				return Math.round((2*dist/100.0/0.9144)*50).toString() + " " + dictionary["yards_" + declension]; 
			} else if (dist < 2414) {
				return dictionary["around_1_mile_" + declension];
			} else if (dist < 16093) {
				return dictionary["around"] + " " + Math.round(dist/1609.3).toString() + " " + dictionary["miles_" + declension];
			} else {
				return Math.round(dist/1609.3).toString() + " " + dictionary["miles_" + declension];
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
	return dictionary["route_calculate"] + " " + distance(dist, "nominativ") + " " + dictionary["time"] + " " + time(seconds) + ". ";
}

function go_ahead(dist, streetName) {
	// go_ahead(Dist, Street) -- ['follow1.ogg', D, 'follow2.ogg'| Sgen]:- distance(Dist, nominativ) -- D, follow_street(Street, Sgen).
	if (dist == -1) {
		return dictionary["go_ahead"];
	} else {
		return dictionary["follow1"] + " " + distance(dist, "nominativ") + " " + dictionary["follow2"] + " " + follow_street(streetName);
	}
}

function follow_street(streetName) {

// follow_street(Street, ['on', SName]) :- tts, Street = voice([R, S, _],[R, S, _]), assemble_street_name(Street, SName).
// follow_street(Street, ['on', SName]) :- tts, Street = voice([R, '', _],[R, _, _]), assemble_street_name(Street, SName).
// follow_street(Street, ['to', 'zur ', SName]) :- tts, not(Street = voice([R, S, _],[R, S, _])), street_is_female(Street), assemble_street_name(Street, SName).
// follow_street(Street, ['to', 'zum ', SName]) :- tts, not(Street = voice([R, S, _],[R, S, _])), street_is_male(Street), assemble_street_name(Street, SName). // Most Refs are female, hence this check only after female check
// follow_street(Street, ['to', SName]) :- tts, not(Street = voice([R, S, _],[R, S, _])), street_is_nothing(Street), assemble_street_name(Street, SName).

	if ((streetName["toDest"] === "" && streetName["toStreetName"] === "" && streetName["toRef"] === "") || Object.keys(streetName).length == 0) {
		return "";
	} else if (streetName["toStreetName"] === "" && streetName["toRef"] === "") {
		return dictionary["to"] + " " + streetName["toDest"];
	} else if (streetName["toRef"] === streetName["fromRef"] && (streetName["toStreetName"] === streetName["fromStreetName"] || streetName["toStreetName"] === "")) {
		return dictionary["on"] + " " + assemble_street_name(streetName);
	} else if (!(streetName["toRef"] === streetName["fromRef"] && streetName["toStreetName"] === streetName["fromStreetName"])) {
		var preposition = isFeminine(streetName) ? dictionary["zur"] : isMasculine(streetName) ? dictionary["zum"] : "";
		return dictionary["to"] + " " + preposition + " " + assemble_street_name(streetName);
	}
}

function turn(turnType, dist, streetName) {
	// turn(Turn, Dist, Street) -- ['after.ogg', D, M, ' '| Sgen] :- distance(Dist, dativ) -- D, turn(Turn, M), turn_street(Street, Sgen).
	if (dist == -1) {
		return getTurnType(turnType) + " " + turn_street(streetName);
	} else {
		return dictionary["after"] + " " + distance(dist, "dativ") + " " + getTurnType(turnType) + " " + turn_street(streetName); 
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
		return dictionary["after"] + " " + distance(dist, "dativ") + " " + dictionary["roundabout"] + " " + dictionary["and"] + " " + dictionary["take"] + " " + nth(exit) + " " + dictionary["exit"] + " " + turn_street(streetName);
	}

}

function turn_street(streetName) {
	

// turn_street(voice(['', '', D], _), ['toward', D]) :- tts.
// turn_street(Street, ['onto', 'die ', SName]) :- tts, not(Street = voice(['', '', D], _)), street_is_female(Street), assemble_street_name(Street, SName).
// turn_street(Street, ['onto', 'den ', SName]) :- tts, not(Street = voice(['', '', D], _)), street_is_male(Street), assemble_street_name(Street, SName). // Most Refs are female, hence this check only after female check
// turn_street(Street, ['onto', SName]) :- tts, not(Street = voice(['', '', D], _)), street_is_nothing(Street), assemble_street_name(Street, SName).

	if ((streetName["toDest"] === "" && streetName["toStreetName"] === "" && streetName["toRef"] === "") || Object.keys(streetName).length == 0) {
		return "";
	} else if (streetName["toStreetName"] === "" && streetName["toRef"] === "") {
		return dictionary["toward"] + " " + streetName["toDest"];
	} else if (streetName["toStreetName"] != "" && streetName["toRef"] != "") {
		var article = isMasculine(streetName) ? dictionary["den"] : isFeminine(streetName) ? dictionary["die"] : "";
		return dictionary["onto"] + " " + article + " " + assemble_street_name(streetName);
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
		return streetName["toRef"] + dictionary["toward"] + streetName["toDest"];
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
// 	make_ut(Dist, Street) --  ['after', D, 'make_uturn1' | Sgen] :- distance(Dist, dativ) -- D, turn_street(Street, Sgen).
// make_ut(Street) -- ['make_uturn2' | Sgen] :- turn_street(Street, Sgen).
	if (dist == -1) {
		return dictionary["make_uturn2"] + " " + turn_street(streetName);
	} else {
		return dictionary["after"] + " " + distance(dist, "dativ") + " " + dictionary["make_uturn1"] + " " + turn_street(streetName);
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
	// prepare_make_ut(Dist, Street) -- ['prepare', 'after', D, 'make_uturn2' | Sgen] :- distance(Dist, dativ) -- D, turn_street(Street, Sgen).

	return dictionary["prepare"] + " " + dictionary["after"] + " " + distance(dist, "dativ") + " " + dictionary["make_uturn2"] + " " + turn_street(streetName);
}

function prepare_turn(turnType, dist, streetName) {
	// prepare_turn(Turn, Dist, Street) -- ['prepare', 'after', D, M | Sgen] :- distance(Dist, dativ) -- D, turn(Turn, M), turn_street(Street, Sgen).
	return dictionary["prepare"] + " " + dictionary["after"] + " " + distance(dist, "dativ") + " " + getTurnType(turnType) + " " + turn_street(streetName);
}

function prepare_roundabout(dist, exit, streetName) {
// prepare_roundabout(Dist, _Exit, _Street) -- ["after", D , "prepare_roundabout"] :- distance(Dist) -- D.
	return dictionary["prepare"] + " " + dictionary["after"] + " " + distance(dist, "dativ") + " " + dictionary["prepare_roundabout"]; 
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
	return dictionary["and_arrive_destination"] + " " + dest + " " + dictionary["reached"];
}

function and_arrive_intermediate(dest) {
	// and_arrive_intermediate(D) -- ["and_arrive_intermediate"|Ds] :- name(D, Ds).
	return dictionary["and_arrive_intermediate"] + " " + dest + " " + dictionary["reached"];
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
	return dictionary["reached_destination"] + " " + dest + " " + dictionary["reached"];
}

function reached_waypoint(dest) {
	return dictionary["reached_waypoint"] + " " + dest;
}

function reached_intermediate(dest) {
	return dictionary["reached_intermediate"] + " " + dest + " " + dictionary["reached"];
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
	return dictionary["off_route"] + " " + distance(dist, "dativ");
}

function back_on_route() {
	return dictionary["back_on_route"];
}

function make_ut_wp() {
	return dictionary["make_ut_wp"];
}


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
// TODO


















// //// resolve command main method
// //// if you are familar with Prolog you can input specific to the whole mechanism,
// //// by adding exception cases.
// flatten(X, Y) :- flatten(X, [], Y), !.
// flatten([], Acc, Acc).
// flatten([X|Y], Acc, Res):- flatten(Y, Acc, R), flatten(X, R, Res).
// flatten(X, Acc, [X|Acc]) :- version(J), J < 100, !.
// flatten(X, Acc, [Y|Acc]) :- string(X, Y), !.
// flatten(X, Acc, [X|Acc]).

// resolve(X, Y) :- resolve_impl(X,Z), flatten(Z, Y).
// resolve_impl([],[]).
// resolve_impl([X|Rest], List) :- resolve_impl(Rest, Tail), ((X -- L) -> append(L, Tail, List); List = Tail).


// // handling alternatives
// [X|_Y] -- T :- (X -- T),!.
// [_X|Y] -- T :- (Y -- T).




// interval(St, St, End, _Step) :- St =< End.
// interval(T, St, End, Step) :- interval(Init, St, End, Step), T is Init + Step, (T =< End -> true; !, fail).

// interval(X, St, End) :- interval(X, St, End, 1).

// string, A) :- voice_generation, interval(X, 1, 19), atom_number(A, X), atom_concat(A, '',).
// string, A) :- voice_generation, interval(X, 20, 95, 5), atom_number(A, X), atom_concat(A, '',).
// string, A) :- voice_generation, interval(X, 100, 140, 10), atom_number(A, X), atom_concat(A, '',).
// string, A) :- voice_generation, interval(X, 150, 950, 50), atom_number(A, X), atom_concat(A, '',).
// string, A) :- voice_generation, interval(X, 1000, 9000, 1000), atom_number(A, X), atom_concat(A, '',).

// dist(X, Y) :- tts, !, num_atom(X, Y).

// dist(0, []) :- !.
// dist(X, ]) :- X < 20, !, pnumber(X,).
// dist(X, ]) :- X < 1000, 0 is X mod 50, !, num_atom(X, A), atom_concat(A, '',).
// dist(D, ['20'|L]) :-  D < 30, Ts is D - 20, !, dist(Ts, L).
// dist(D, ['30'|L]) :-  D < 40, Ts is D - 30, !, dist(Ts, L).
// dist(D, ['40'|L]) :-  D < 50, Ts is D - 40, !, dist(Ts, L).
// dist(D, ['50'|L]) :-  D < 60, Ts is D - 50, !, dist(Ts, L).
// dist(D, ['60'|L]) :-  D < 70, Ts is D - 60, !, dist(Ts, L).
// dist(D, ['70'|L]) :-  D < 80, Ts is D - 70, !, dist(Ts, L).
// dist(D, ['80'|L]) :-  D < 90, Ts is D - 80, !, dist(Ts, L).
// dist(D, ['90'|L]) :-  D < 100, Ts is D - 90, !, dist(Ts, L).
// dist(D, ['100'|L]) :-  D < 200, Ts is D - 100, !, dist(Ts, L).
// dist(D, ['200'|L]) :-  D < 300, Ts is D - 200, !, dist(Ts, L).
// dist(D, ['300'|L]) :-  D < 400, Ts is D - 300, !, dist(Ts, L).
// dist(D, ['400'|L]) :-  D < 500, Ts is D - 400, !, dist(Ts, L).
// dist(D, ['500'|L]) :-  D < 600, Ts is D - 500, !, dist(Ts, L).
// dist(D, ['600'|L]) :-  D < 700, Ts is D - 600, !, dist(Ts, L).
// dist(D, ['700'|L]) :-  D < 800, Ts is D - 700, !, dist(Ts, L).
// dist(D, ['800'|L]) :-  D < 900, Ts is D - 800, !, dist(Ts, L).
// dist(D, ['900'|L]) :-  D < 1000, Ts is D - 900, !, dist(Ts, L).
// dist(D, ['1000'|L]):- Ts is D - 1000, !, dist(Ts, L).

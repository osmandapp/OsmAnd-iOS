
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
dictionary["route_is"] = "Маршрут составляет ";
dictionary["route_calculate"] = "Маршрут пересчитывается";
dictionary["distance"] = "расстояние ";

// LEFT/RIGHT
dictionary["prepare"] = "Приготовьтесь ";
dictionary["after"] = "через ";

dictionary["left"] = "поверните налево";
dictionary["left_sh"] = "резко поверните налево";
dictionary["left_sl"] = "плавно поверните налево";
dictionary["right"] = "поверните направо";
dictionary["right_sh"] = "резко поверните направо";
dictionary["right_sl"] = "плавно поверните направо";
dictionary["left_keep"] = "держитесь левее";
dictionary["right_keep"] = "держитесь правее";
dictionary["left_bear"] = "держитесь левее";    // in English the same as left_keep, may be different in other languages
dictionary["right_bear"] = "держитесь правее";  // in English the same as right_keep, may be different in other languages

// U-TURNS
dictionary["make_uturn"] = "Выполните разворот";
dictionary["make_uturn_wp"] = "При возможности, выполните разворот";

// ROUNDABOUTS
dictionary["prepare_roundabout"] = "Приготовьтесь въехать на кольцо ";
dictionary["roundabout"] = "въедьте на кольцо, ";
dictionary["then"] = " затем ";
dictionary["and"] = " и ";
dictionary["take"] = "выполните ";
dictionary["exit"] = "съезд";

dictionary["1na"] = "одна ";
dictionary["2ve"] = "две ";

dictionary["1th"] = "первый ";
dictionary["2th"] = "второй ";
dictionary["3th"] = "третий ";
dictionary["4th"] = "четвертый ";
dictionary["5th"] = "пятый ";
dictionary["6th"] = "шестой ";
dictionary["7th"] = "седьмой ";
dictionary["8th"] = "восьмой ";
dictionary["9th"] = "девятый ";
dictionary["10th"] = "десятый ";
dictionary["11th"] = "одиннадцатый ";
dictionary["12th"] = "двенадцатый ";
dictionary["13th"] = "тринадцатый ";
dictionary["14th"] = "четырнадцатый ";
dictionary["15th"] = "пятнадцатый ";
dictionary["16th"] = "шестнадцатый ";
dictionary["17th"] = "семнадцатый ";

// STRAIGHT/FOLLOW
dictionary["go_ahead"] = "Продолжайте движение прямо";
dictionary["follow"] = "Продолжайте движение ";

// ARRIVE
dictionary["and_arrive_destination"] = "и вы прибудете в пункт назначения ";
dictionary["reached_destination"] = "вы прибыли в пункт назначения ";
dictionary["and_arrive_intermediate"] = "и вы прибудете в промежуточный пункт ";
dictionary["reached_intermediate"] = "вы прибыли в промежуточный пункт ";

// NEARBY POINTS
dictionary["and_arrive_waypoint"] = "и вы подъедете к ДЖИ-ПИ-ИКС точке ";
dictionary["reached_waypoint"] = "вы проезжаете ДЖИ-ПИ-ИКС точку ";
dictionary["and_arrive_favorite"] = "и вы подъедете к точке из избранного ";
dictionary["reached_favorite"] = "вы проезжаете точку из избранного ";
dictionary["and_arrive_poi"] = "и вы подъедете к точке ПОИ ";
dictionary["reached_poi"] = "вы проезжаете точку ПОИ ";

// ATTENTION
//dictionary["exceed_limit"] = "Вы превысили допустимую скорость ";
dictionary["exceed_limit"] = "ограничение скорости ";
dictionary["attention"] = "Внимание, ";
dictionary["speed_camera"] = "камера";
dictionary["border_control"] = "пограничный пункт";
dictionary["railroad_crossing"] = "железная дорога";
dictionary["traffic_calming"] = "искуственная неровность";
dictionary["toll_booth"] = "пункт оплаты проезда";
dictionary["stop"] = "знак Стоп";
dictionary["pedestrian_crosswalk"] = "пешеходный переход";
dictionary["tunnel"] = "тоннель";

// OTHER PROMPTS
dictionary["location_lost"] = "потерян сигнал ДЖИ-ПИ-ЭС";
dictionary["location_recovered"] = "ДЖИ-ПИ-ЭС сигнал восстановлен";
dictionary["off_route"] = "Вы отклонились от маршрута на ";
dictionary["back_on_route"] = "Вы вернулись на маршрут";

// STREET NAME PREPOSITIONS
dictionary["on"] = "по ";
dictionary["onto"] = "на ";
dictionary["to"] = "до ";
dictionary["toward"] = "к ";

// DISTANCE UNIT SUPPORT
dictionary["metr"] = "метр";
dictionary["metra"] = "метра";
dictionary["metrov"] = "метров";
dictionary["kilometr"] = "километр";
dictionary["kilometra"] = "километра";
dictionary["kilometrov"] = "километров";
//dictionary["around_1_kilometer"] = "около одного километра";
dictionary["around"] = "примерно ";

dictionary["footov"] = "футов";
dictionary["around_1_mile"] = "около одной мили";
dictionary["1_tenth_of_a_mile"] = "одна десятая мили";
dictionary["tenths_of_a_mile"] = " десятых мили";
dictionary["1mile"] = "миля";
dictionary["2mili"] = "мили";
dictionary["5mil"] = "миль";

dictionary["yardov"] = "ярдов";

// TIME SUPPORT
dictionary["time"] = "время ";
dictionary["hour"] = "час ";
dictionary["hours_a"] = "часа ";
dictionary["hours_ov"] = "часов ";
dictionary["less_a_minute"] = "менее минуты";
dictionary["minute"] = "минута";
dictionary["minute_i"] = "минуты";
dictionary["minutes"] = "минут";


//// COMMAND BUILDING / WORD ORDER
////////////////////////////////////////////////////////////////
function setMetricConst(metrics) {
	metricConst = metrics;
}


function route_new_calc(dist, timeVal) {
	return dictionary["route_is"] + " " + distance(dist) + " " + dictionary["time"] + " " + time(timeVal) + ". ";
}

function plural_mt(dist) {
	if (distance % 10 == 1 && (dist % 100 > 20 || dist % 100 < 10)) {
		return dictionary["metr"];
	} else if (dist % 10 < 5 && dist % 10 > 1 && (dist % 100 > 20 || dist % 100 < 10 )) {
		return dictionary["metra"];
	} else {
		return dictionary["metrov"];
	}
}

function plural_km(dist) {
	if (distance % 10 == 1 && (dist % 100 > 20 || dist % 100 < 10)) {
		return dictionary["kilometr"];
	} else if (dist % 10 < 5 && dist % 10 > 1 && (dist % 100 > 20 || dist % 100 < 10 )) {
		return dictionary["kilometra"];
	} else {
		return dictionary["kilometrov"];
	}
}

function plural_mi(dist) {
	if (distance % 10 == 1 && (dist % 100 > 20 || dist % 100 < 10)) {
		return dictionary["1mile"];
	} else if (dist % 10 < 5 && dist % 10 > 1 && (dist % 100 > 20 || dist % 100 < 10 )) {
		return dictionary["2mili"];
	} else {
		return dictionary["5mil"];
	}
}


function distance(dist) {
	switch (metricConst) {
		case "km-m":
			if (dist < 100) {
				return Math.round(dist).toString() + " " + plural_mt(dist);
			} else if (dist < 1000) {
				var distance = Math.round((dist/10.0)*10);
				return distance.toString() + " " + plural_mt(distance);
			} else if (dist < 1500) {
				return dictionary["around"] + " 1 " + dictionary["kilometr"];
			} else {
				return Math.round(dist/1000.0).toString() + " " + plural_km(dist/1000.0);
			}
			break;
		case "mi-f":
			if (dist < 160) {
				return Math.round((2*dist/100.0/0.3048)*50).toString(); + " " + dictionary["footov"];
			} else if (dist < 241) {
				return dictionary["1_tenth_of_a_mile"];
			} else if (dist < 1529) {
				return Math.round(dist/161.0).toString() + " " + dictionary["tenths_of_a_mile"];
			} else if (dist < 2414) {
				return dictionary["around_1_mile"];
			} else if (dist < 16093) {
				return dictionary["around"] + " " + Math.round(dist/1609.3).toString() + " " + dictionary["miles"];
			} else {
				return Math.round(dist/1609.3).toString() + " " + plural_mi(dist/1609.3);
			}
			break;
		case "mi-m":
			if (dist < 100) {
				return Math.round(dist).toString() + " " + plural_mt(dist);
			} else if (dist < 1300) {
				var distance = Math.round((Dist/10.0)*10);
				return distance.toString() + " " + plural_mt(distance);
			} else if (dist < 2414) {
				return dictionary["around_1_mile"];
			} else {
				return Math.round(dist/1609.3).toString() + " " + plural_mi(dist/1609.3);
			}
			break;
		case "mi/y":
			if (dist < 17) {
				return Math.round(dist/0.9144).toString() + " " + dictionary["yardov"];
			} else if (dist < 100) {
				return Math.round((dist/10.0/0.9144)*10).toString() + " " + dictionary["yardov"];
			} else if (dist < 1300) {
				return Math.round((2*dist/100.0/0.9144)*50).toString() + " " + dictionary["yards"]; 
			} else if (dist < 2414) {
				return dictionary["around_1_mile"];
			} else {
				return Math.round(dist/1609.3).toString() + " " + plural_mi(dist/1609.3);
			}
			break;
	}
}

function plural_hs(time) {
	if (time % 10 == 1 && (time % 100 > 20 || time % 100 < 10)) {
		return dictionary["hour"];
	} else if (time % 10 > 1 && time % 10 < 5 && (time % 100 > 20 || time % 100 < 10)) {
		return dictionary["hours_a"];
	} else {
		return dictionary["hours_ov"];
	}
}


function plural_mn(time) {
	if (time % 10 == 1 && (time % 100 > 20 || time % 100 < 10)) {
		return dictionary["minute"];
	} else if (time % 10 > 1 && time % 10 < 5 && (time % 100 > 20 || time % 100 < 10)) {
		return dictionary["minute_i"];
	} else {
		return dictionary["minutes"];
	}
}

function time(seconds) {
	var minutes = Math.round(seconds/60.0);
	if (seconds < 30) {
		return dictionary["less_a_minute"];
	} else if (minutes % 60 == 1 || minutes < 60) {
		return minutes + " " + plural_mn(minutes);
	} else  {
		return Math.round(minutes/60).toString() + " " + plural_hs(minutes/60);
	}
}

function route_recalc(dist, seconds) {
	return dictionary["route_calculate"] + " " + distance(dist) + " " + dictionary["time"] + " " + time(seconds) + ". ";
}

function go_ahead(dist, streetName) {
	if (dist == -1) {
		return dictionary["go_ahead"];
	} else {
		return dictionary["follow"] + " " + distance(dist) + " " + follow_street(streetName);
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
	} else if ((streetName["toRef"] === streetName["fromRef"] && streetName["toStreetName"] === streetName["fromStreetName"]) 
		|| (streetName["toStreetName"] === "" && streetName["toRef"] === streetName["fromRef"])) {
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
	// turn(Turn, Dist, Street) -- ["after", D, M | Sgen] :- distance(Dist) -- D, turn(Turn, M), turn_street(Street, Sgen).
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

// roundabout(Dist, _Angle, Exit, Street) -- ['after', D, 'roundabout', 'and', 'take', E, 'exit' | Sgen] :- distance(Dist) -- D, nth(Exit, E), turn_street(Street, Sgen).
// roundabout(_Angle, Exit, Street) -- ['take', E, 'exit' | Sgen] :- nth(Exit, E), turn_street(Street, Sgen).
	if (dist == -1) {
		return dictionary["take"] + " " + nth(exit) + " " + dictionary["exit"] + " " + turn_street(streetName);
	} else {
		return dictionary["after"] + " " + distance(dist) + " " + dictionary["roundabout"] + " " + dictionary["and"] + " " + dictionary["take"] + " " + nth(exit) + " " + dictionary["exit"] + " " + turn_street(streetName);
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
		return dictionary["on"] + " " + assemble_street_name(streetName);
	} else if (streetName["toStreetName"] === "" && streetName["toRef"] === streetName["fromRef"]) {
		return dictionary["on"] + " " + assemble_street_name(streetName);
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
		return streetName["toRef"] + dictionary["toward"] + streetName["toDest"];
	}
}

function nth(exit) {
	switch (exit) {
		case (1):
			return dictionary["1th"];
		case (2):
			return dictionary["2th"];
		case (3):
			return dictionary["3th"];
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
	// make_ut(Dist, Street) --  ["after", D, "make_uturn" | Sgen] :- distance(Dist) -- D, turn_street(Street, Sgen).
// make_ut(Street) -- ["make_uturn" | Sgen] :- turn_street(Street, Sgen).
	if (dist == -1) {
		return dictionary["make_uturn"] + " " + turn_street(streetName);
	} else {
		return dictionary["after"] + " " + distance(dist) + " " + dictionary["make_uturn"] + " " + turn_street(streetName);
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
	return dictionary["after"] + " " + distance(dist) + " " + dictionary["make_uturn"] + " " + turn_street(streetName);
}

function prepare_turn(turnType, dist, streetName) {
	// prepare_turn(Turn, Dist, Street) -- ["after", D, M | Sgen] :- distance(Dist) -- D, turn(Turn, M), turn_street(Street, Sgen).
	return dictionary["after"] + " " + distance(dist) + " " + getTurnType(turnType) + " " + turn_street(streetName);
}

function prepare_roundabout(dist, exit, streetName) {
// prepare_roundabout(Dist, _Exit, _Street) -- ['prepare_roundabout', 'after', D, 'and', 'take', E, 'exit' | Sgen] :- distance(Dist) -- D, nth(_Exit, E), turn_street(_Street, Sgen).
	return dictionary["prepare_roundabout"] + " " + dictionary["after"] + " " + distance(dist) + " " + dictionary["and"] + " " + dictionary["take"] + " " + nth(exit) + " " + dictionary["exit"]; 
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



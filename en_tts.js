
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
dictionary["route_is"] = "The trip is ";
dictionary["route_calculate"] = "Route recalculated";
dictionary["distance"] = "distance ";

// LEFT/RIGHT
//dictionary["prepare"] = "Prepare to "
dictionary["after"] = "after ";
dictionary["in"] = "in ";

dictionary["left"] = "turn left";
dictionary["left_sh"] = "turn sharply left";
dictionary["left_sl"] = "turn slightly left";
dictionary["right"] = "turn right";
dictionary["right_sh"] = "turn sharply right";
dictionary["right_sl"] = "turn slightly right";
dictionary["left_keep"] = "keep left";
dictionary["right_keep"] = "keep right";
dictionary["left_bear"] = "keep left";    // in English the same as left_keep, may be different in other languages
dictionary["right_bear"] = "keep right";  // in English the same as right_keep, may be different in other languages

// U-TURNS
dictionary["make_uturn"] = "Make a U turn";
dictionary["make_uturn_wp"] = "When possible, please make a U turn";

// ROUNDABOUTS
dictionary["prepare_roundabout"] = "enter a roundabout";
dictionary["roundabout"] = "enter the roundabout, ";
dictionary["then"] = ", then ";
dictionary["and"] = " and ";
dictionary["take"] = "take the ";
dictionary["exit"] = "exit";

dictionary["1st"] = "first ";
dictionary["2nd"] = "second ";
dictionary["3rd"] = "third ";
dictionary["4th"] = "fourth ";
dictionary["5th"] = "fifth ";
dictionary["6th"] = "sixth ";
dictionary["7th"] = "seventh ";
dictionary["8th"] = "eighth ";
dictionary["9th"] = "nineth ";
dictionary["10th"] = "tenth ";
dictionary["11th"] = "eleventh ";
dictionary["12th"] = "twelfth ";
dictionary["13th"] = "thirteenth ";
dictionary["14th"] = "fourteenth ";
dictionary["15th"] = "fifteenth ";
dictionary["16th"] = "sixteenth ";
dictionary["17th"] = "seventeenth ";

// STRAIGHT/FOLLOW
dictionary["go_ahead"] = "Go straight ahead";
dictionary["follow"] = "Continue for ";  // "Follow the course of the road for" perceived as too chatty by many users

// ARRIVE
dictionary["and_arrive_destination"] = "and arrive at your destination ";
dictionary["reached_destination"] = "you have reached your destination ";
dictionary["and_arrive_intermediate"] = "and arrive at your intermediate destination ";
dictionary["reached_intermediate"] = "you have reached your intermediate destination ";

// NEARBY POINTS
dictionary["and_arrive_waypoint"] = "and pass GPX waypoint ";
dictionary["reached_waypoint"] = "you are passing GPX waypoint ";
dictionary["and_arrive_favorite"] = "and pass favorite ";
dictionary["reached_favorite"] = "you are passing favorite ";
dictionary["and_arrive_poi"] = "and pass POI ";
dictionary["reached_poi"] = "you are passing POI ";

// ATTENTION
//dictionary["exceed_limit"] = "you are exceeding the speed limit "
dictionary["exceed_limit"] = "speed limit ";
dictionary["attention"] = "attention, ";
dictionary["speed_camera"] = "speed cam";
dictionary["border_control"] = "border control";
dictionary["railroad_crossing"] = "railroad crossing";
dictionary["traffic_calming"] = "traffic calming";
dictionary["toll_booth"] = "toll booth";
dictionary["stop"] = "stop sign";
dictionary["pedestrian_crosswalk"] = "pedestrian crosswalk";
dictionary["tunnel"] = "tunnel";

// OTHER PROMPTS
dictionary["location_lost"] = "g p s signal lost";
dictionary["location_recovered"] = "g p s signal recovered";
dictionary["off_route"] = "you have been off the route for";
dictionary["back_on_route"] = "you are back on the route";

// STREET NAME PREPOSITIONS
dictionary["onto"] = "onto ";
dictionary["on"] = "on ";    // is used if you turn together with your current street, i.e. street name does not change.
dictionary["to"] = "to ";
dictionary["toward"] = "toward ";

// DISTANCE UNIT SUPPORT
dictionary["meters"] = "meters";
dictionary["around_1_kilometer"] = "about 1 kilometer";
dictionary["around"] = "about ";
dictionary["kilometers"] = "kilometers";

dictionary["feet"] = "feet";
dictionary["1_tenth_of_a_mile"] = "one tenth of a mile";
dictionary["tenths_of_a_mile"] = "tenths of a mile";
dictionary["around_1_mile"] = "about 1 mile";
dictionary["miles"] = "miles";
dictionary["yards"] = "yards";

// TIME SUPPORT
dictionary["time"] = "time is ";
dictionary["1_hour"] = "one hour ";
dictionary["hours"] = "hours "
dictionary["less_a_minute"] = "less than a minute";
dictionary["1_minute"] = "one minute";
dictionary["minutes"] = "minutes";

//// COMMAND BUILDING / WORD ORDER
////////////////////////////////////////////////////////////////
function setMetricConst(metrics) {
	metricConst = metrics;
}


function route_new_calc(dist, timeVal) {
	return dictionary["route_is"] + " " + distance(dist, metricConst) + " " + dictionary["time"] + " " + time(timeVal) + ". ";
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

function route_recalc(dist, time) {
	return dictionary["route_calculate"] + " " + distance(dist, metricConst) + " " + dictionary["time"] + " " + time(time) + ". ";
}

function go_ahead(dist, streetName) {
	if (dist == -1 && streetName == undefined) {
		return dictionary["go_ahead"];
	} else {
		return dictionary["follow"] + " " + distance(dist) + " " + dictionary["on"] + " " + streetName;
	}
	
// go_ahead(Dist, Street) -- ["follow", D | Sgen] :- distance(Dist) -- D, follow_street(Street, Sgen).
// follow_street("", []).
// follow_street(voice(["","",""],_), []).
// follow_street(voice(["", "", D], _), ["to", D]) :- tts.
// follow_street(Street, ["on", SName]) :- tts, Street = voice([R, S, _],[R, S, _]), assemble_street_name(Street, SName).
// follow_street(Street, ["on", SName]) :- tts, Street = voice([R, "", _],[R, _, _]), assemble_street_name(Street, SName).
// follow_street(Street, ["to", SName]) :- tts, not(Street = voice([R, S, _],[R, S, _])), assemble_street_name(Street, SName).
}

function turn(turnType, distance, streetName) {
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
// turn("left", ).
// turn("left_sh", ["left_sh"]).
// turn("left_sl", ["left_sl"]).
// turn("right", ["right"]).
// turn("right_sh", ["right_sh"]).
// turn("right_sl", ["right_sl"]).
// turn("left_keep", ["left_keep"]).
// turn("right_keep", ["right_keep"]).
// // Note: turn("left_keep"/"right_keep",[]) is a turn type aiding lane selection, while bear_left()/bear_right() is triggered as brief "turn-after-next" preparation sounding always after a "..., then...". In some languages turn(l/r_keep) may not differ from bear_l/r:
// bear_left(_Street) -- ["left_bear"].
// bear_right(_Street) -- ["right_bear"].

// // assemble_street_name(voice([Ref, Name, Dest], [_CurrentRef, _CurrentName, _CurrentDest]), _).
// // assemble_street_name(voice(["", Name, _], _), Name). // not necessary
// // Next 2 lines for Name taking precedence over Dest...
// //assemble_street_name(voice([Ref, "", Dest], _), [C1, "toward", Dest]) :- atom_concat(Ref, " ", C1).
// //assemble_street_name(voice([Ref, Name, _], _), Concat) :- atom_concat(Ref, " ", C1), atom_concat(C1, Name, Concat).
// // ...or next 3 lines for Dest taking precedence over Name
// assemble_street_name(voice([Ref, Name, ""], _), Concat) :- atom_concat(Ref, " ", C1), atom_concat(C1, Name, Concat).
// assemble_street_name(voice(["", Name, Dest], _), [C1, "toward", Dest]) :- atom_concat(Name, " ", C1).
// assemble_street_name(voice([Ref, _, Dest], _), [C1, "toward", Dest]) :- atom_concat(Ref, " ", C1).

// turn_street("", []).
// turn_street(voice(["","",""],_), []).
// turn_street(voice(["", "", D], _), ["toward", D]) :- tts.
// turn_street(Street, ["on", SName]) :- tts, Street = voice([R, S, _],[R, S, _]), assemble_street_name(Street, SName).
// turn_street(Street, ["on", SName]) :- tts, Street = voice([R, "", _],[R, _, _]), assemble_street_name(Street, SName).
// turn_street(Street, ["onto", SName]) :- tts, not(Street = voice([R, S, _],[R, S, _])), assemble_street_name(Street, SName).
// turn_street(_Street, []) :- not(tts).



// prepare_turn(Turn, Dist, Street) -- ["after", D, M | Sgen] :- distance(Dist) -- D, turn(Turn, M), turn_street(Street, Sgen).
// turn(Turn, Dist, Street) -- ["in", D, M | Sgen] :- distance(Dist) -- D, turn(Turn, M), turn_street(Street, Sgen).
// turn(Turn, Street) -- [M | Sgen] :- turn(Turn, M), turn_street(Street, Sgen).

// prepare_make_ut(Dist, Street) -- ["after", D, "make_uturn" | Sgen] :- distance(Dist) -- D, turn_street(Street, Sgen).
// make_ut(Dist, Street) --  ["in", D, "make_uturn" | Sgen] :- distance(Dist) -- D, turn_street(Street, Sgen).
// make_ut(Street) -- ["make_uturn" | Sgen] :- turn_street(Street, Sgen).
// make_ut_wp -- ["make_uturn_wp"].

// prepare_roundabout(Dist, _Exit, _Street) -- ["after", D , "prepare_roundabout"] :- distance(Dist) -- D.
// roundabout(Dist, _Angle, Exit, Street) -- ["in", D, "roundabout", "and", "take", E, "exit" | Sgen] :- distance(Dist) -- D, nth(Exit, E), turn_street(Street, Sgen).
// roundabout(_Angle, Exit, Street) -- ["take", E, "exit" | Sgen] :- nth(Exit, E), turn_street(Street, Sgen).


// then -- ["then"].
// name(D, [D]) :- tts.
// name(_D, []) :- not(tts).

// and_arrive_destination(D) -- ["and_arrive_destination"|Ds] :- name(D, Ds).
// reached_destination(D) -- ["reached_destination"|Ds] :- name(D, Ds).
// and_arrive_intermediate(D) -- ["and_arrive_intermediate"|Ds] :- name(D, Ds).
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

// // TRAFFIC WARNINGS
// speed_alarm(MaxSpeed, _Speed) -- ["exceed_limit", I] :- pnumber(MaxSpeed, I).
// attention(Type) -- ["attention", W] :- warning(Type, W).
// warning("SPEED_CAMERA", "speed_camera").
// warning("SPEED_LIMIT", "").
// warning("BORDER_CONTROL", "border_control").
// warning("RAILWAY", "railroad_crossing").
// warning("TRAFFIC_CALMING", "traffic_calming").
// warning("TOLL_BOOTH", "toll_booth").
// warning("STOP", "stop").
// warning("PEDESTRIAN", "pedestrian_crosswalk").
// warning("MAXIMUM", "").
// warning("TUNNEL", "tunnel").
// warning(Type, "") :- not(Type = "SPEED_CAMERA"; Type = "SPEED_LIMIT"; Type = "BORDER_CONTROL"; Type = "RAILWAY"; Type = "TRAFFIC_CALMING"; Type = "TOLL_BOOTH"; Type = "STOP"; Type = "PEDESTRIAN"; Type = "MAXIMUM"; Type = "TUNNEL").


// //// 
// nth(1, "1st").
// nth(2, "2nd").
// nth(3, "3rd").
// nth(4, "4th").
// nth(5, "5th").
// nth(6, "6th").
// nth(7, "7th").
// nth(8, "8th").
// nth(9, "9th").
// nth(10, "10th").
// nth(11, "11th").
// nth(12, "12th").
// nth(13, "13th").
// nth(14, "14th").
// nth(15, "15th").
// nth(16, "16th").
// nth(17, "17th").


// //// command main method
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
// resolve_impl([X|Rest], List) :- resolve_impl(Rest, Tail), ("--"(X, L) -> append(L, Tail, List); List = Tail).


// // handling alternatives
// [X|_Y] -- T :- (X -- T),!.
// [_X|Y] -- T :- (Y -- T).


// pnumber(X, Y) :- tts, !, num_atom(X, Y).
// pnumber(X, Ogg) :- num_atom(X, A), atom_concat(A, "", Ogg).
// // time measure


// ////// distance measure
// distance(Dist) -- D :- measure("km-m"), distance_km(Dist) -- D.
// distance(Dist) -- D :- measure("mi-f"), distance_mi_f(Dist) -- D.
// distance(Dist) -- D :- measure("mi-y"), distance_mi_y(Dist) -- D.
// distance(Dist) -- D :- measure("mi-m"), distance_mi_m(Dist) -- D.

// ////// distance measure km/m


// ////// distance measure mi/f


// ////// distance measure mi/y


// ////// distance measure mi/m



// interval(St, St, End, _Step) :- St =< End.
// interval(T, St, End, Step) :- interval(Init, St, End, Step), T is Init + Step, (T =< End -> true; !, fail).

// interval(X, St, End) :- interval(X, St, End, 1).

// // string(Ogg, A) :- voice_generation, interval(X, 1, 19), atom_number(A, X), atom_concat(A, "", Ogg).
// // string(Ogg, A) :- voice_generation, interval(X, 20, 95, 5), atom_number(A, X), atom_concat(A, "", Ogg).
// // string(Ogg, A) :- voice_generation, interval(X, 100, 140, 10), atom_number(A, X), atom_concat(A, "", Ogg).
// // string(Ogg, A) :- voice_generation, interval(X, 150, 950, 50), atom_number(A, X), atom_concat(A, "", Ogg).
// // string(Ogg, A) :- voice_generation, interval(X, 1000, 9000, 1000), atom_number(A, X), atom_concat(A, "", Ogg).

// // // dist(X, Y) :- tts, !, num_atom(X, Y).

// // // dist(0, []) :- !.
// // // dist(X, [Ogg]) :- X < 20, !, pnumber(X, Ogg).
// // // dist(X, [Ogg]) :- X < 1000, 0 is X mod 50, !, num_atom(X, A), atom_concat(A, "", Ogg).
// // // dist(D, ["20"|L]) :-  D < 30, Ts is D - 20, !, dist(Ts, L).
// // // dist(D, ["30"|L]) :-  D < 40, Ts is D - 30, !, dist(Ts, L).
// // // dist(D, ["40"|L]) :-  D < 50, Ts is D - 40, !, dist(Ts, L).
// // // dist(D, ["50"|L]) :-  D < 60, Ts is D - 50, !, dist(Ts, L).
// // // dist(D, ["60"|L]) :-  D < 70, Ts is D - 60, !, dist(Ts, L).
// // // dist(D, ["70"|L]) :-  D < 80, Ts is D - 70, !, dist(Ts, L).
// // // dist(D, ["80"|L]) :-  D < 90, Ts is D - 80, !, dist(Ts, L).
// // // dist(D, ["90"|L]) :-  D < 100, Ts is D - 90, !, dist(Ts, L).
// // // dist(D, ["100"|L]) :-  D < 200, Ts is D - 100, !, dist(Ts, L).
// // // dist(D, ["200"|L]) :-  D < 300, Ts is D - 200, !, dist(Ts, L).
// // // dist(D, ["300"|L]) :-  D < 400, Ts is D - 300, !, dist(Ts, L).
// // // dist(D, ["400"|L]) :-  D < 500, Ts is D - 400, !, dist(Ts, L).
// // // dist(D, ["500"|L]) :-  D < 600, Ts is D - 500, !, dist(Ts, L).
// // // dist(D, ["600"|L]) :-  D < 700, Ts is D - 600, !, dist(Ts, L).
// // // dist(D, ["700"|L]) :-  D < 800, Ts is D - 700, !, dist(Ts, L).
// // // dist(D, ["800"|L]) :-  D < 900, Ts is D - 800, !, dist(Ts, L).
// // // dist(D, ["900"|L]) :-  D < 1000, Ts is D - 900, !, dist(Ts, L).
// // // dist(D, ["1000"|L]):- Ts is D - 1000, !, dist(Ts, L).

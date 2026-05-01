extends Node

const SWLogger = preload("res://addons/silent_wolf/utils/SWLogger.gd")
const UUID = preload("res://addons/silent_wolf/utils/UUID.gd")
const SWHashing = preload("res://addons/silent_wolf/utils/SWHashing.gd")
const SWUtils = preload("res://addons/silent_wolf/utils/SWUtils.gd")

# signals
signal sw_get_scores_complete
signal sw_get_player_scores_complete
signal sw_top_player_score_complete
signal sw_get_position_complete
signal sw_get_scores_around_complete
signal sw_save_score_complete
signal sw_wipe_leaderboard_complete
signal sw_delete_score_complete

# leaderboard scores by leaderboard name
var leaderboards = {}
var leaderboards_past_periods = {}
var ldboard_config = {}

var scores = []
var player_scores = []
var player_top_score = null
var local_scores = []
var score_id = ""
var position = 0
var latest_max = 10

# request nodes
var SaveScore = null
var GetScores = null
var ScorePosition = null
var ScoresAround = null
var ScoresByPlayer = null
var TopScoreByPlayer = null
var WipeLeaderboard = null
var DeleteScore = null

# weakrefs
var wrSaveScore = null
var wrGetScores = null
var wrScorePosition = null
var wrScoresAround = null
var wrScoresByPlayer = null
var wrTopScoreByPlayer = null
var wrWipeLeaderboard = null
var wrDeleteScore = null

func save_score(player_name: String, score, ldboard_name: String="main", metadata: Dictionary={}) -> Node:
	if player_name == null or player_name == "":
		SWLogger.error("ERROR in SilentWolf.Scores.persist_score - please enter a valid player name")
	else:
		var prepared_http_req = SilentWolf.prepare_http_request()
		SaveScore = prepared_http_req.request
		wrSaveScore = prepared_http_req.weakref
		SaveScore.request_completed.connect(_on_SaveScore_request_completed)
		var game_id = SilentWolf.config.game_id
		score_id = UUID.generate_uuid_v4()
		var payload = { "score_id" : score_id, "player_name" : player_name, "game_id": game_id, "score": score, "ldboard_name": ldboard_name }
		if !metadata.is_empty(): payload["metadata"] = metadata
		add_to_local_scores(payload)
		SilentWolf.send_post_request(SaveScore, "https://api.silentwolf.com/save_score", payload)
	return self

func _on_SaveScore_request_completed(result, response_code, headers, body) -> void:
	var status_check = SWUtils.check_http_response(response_code, headers, body)
	SilentWolf.free_request(wrSaveScore, SaveScore)
	if status_check:
		var json_body = JSON.parse_string(body.get_string_from_utf8())
		var sw_result: Dictionary = SilentWolf.build_result(json_body)
		if typeof(json_body) == TYPE_DICTIONARY and json_body.has("success") and json_body.success:
			sw_result["score_id"] = json_body.score_id
		else:
			var err = json_body.error if typeof(json_body) == TYPE_DICTIONARY and json_body.has("error") else "Unknown Error"
			SWLogger.error("SilentWolf save score failure: " + str(err))
		sw_save_score_complete.emit(sw_result)

func get_scores(maximum: int=10, ldboard_name: String="main", period_offset: int=0) -> Node:
	var prepared_http_req = SilentWolf.prepare_http_request()
	GetScores = prepared_http_req.request
	wrGetScores = prepared_http_req.weakref
	GetScores.request_completed.connect(_on_GetScores_request_completed)
	latest_max = maximum
	var request_url = "https://api.silentwolf.com/get_scores/" + str(SilentWolf.config.game_id) + "?max=" + str(maximum) + "&ldboard_name=" + str(ldboard_name) + "&period_offset=" + str(period_offset)
	SilentWolf.send_get_request(GetScores, request_url)
	return self

func _on_GetScores_request_completed(result, response_code, headers, body) -> void:
	var status_check = SWUtils.check_http_response(response_code, headers, body)
	SilentWolf.free_request(wrGetScores, GetScores)
	if status_check:
		var json_body = JSON.parse_string(body.get_string_from_utf8())
		var sw_result: Dictionary = SilentWolf.build_result(json_body)
		if typeof(json_body) == TYPE_DICTIONARY and json_body.has("success") and json_body.success:
			scores = translate_score_fields_in_array(json_body.top_scores)
			var ld_name = json_body.ld_name
			if "period_offset" in json_body:
				leaderboards_past_periods[ld_name + ";" + str(json_body["period_offset"])] = scores
			else:
				leaderboards[ld_name] = scores
			ldboard_config[ld_name] = json_body.ld_config
			sw_result["scores"] = scores
			sw_result["ld_name"] = ld_name
		else:
			var err = json_body.error if typeof(json_body) == TYPE_DICTIONARY and json_body.has("error") else "API Error 403/Forbidden"
			SWLogger.error("SilentWolf get scores failure: " + str(err))
		sw_get_scores_complete.emit(sw_result)

func get_score_position(score, ldboard_name: String="main") -> Node:
	var prepared_http_req = SilentWolf.prepare_http_request()
	ScorePosition = prepared_http_req.request
	wrScorePosition = prepared_http_req.weakref
	ScorePosition.request_completed.connect(_on_GetScorePosition_request_completed)
	var payload = { "game_id": SilentWolf.config.game_id, "ldboard_name": ldboard_name }
	if UUID.is_uuid(str(score)): payload["score_id"] = score
	else: payload["score_value"] = score
	SilentWolf.send_post_request(ScorePosition, "https://api.silentwolf.com/get_score_position", payload)
	return self

func _on_GetScorePosition_request_completed(result, response_code, headers, body) -> void:
	var status_check = SWUtils.check_http_response(response_code, headers, body)
	SilentWolf.free_request(wrScorePosition, ScorePosition)
	if status_check:
		var json_body = JSON.parse_string(body.get_string_from_utf8())
		var sw_result: Dictionary = SilentWolf.build_result(json_body)
		if typeof(json_body) == TYPE_DICTIONARY and json_body.has("success") and json_body.success:
			sw_result["position"] = int(json_body.position)
		else:
			var err = json_body.error if typeof(json_body) == TYPE_DICTIONARY and json_body.has("error") else "Error"
			SWLogger.error("SilentWolf get position failure: " + str(err))
		sw_get_position_complete.emit(sw_result)

# Хелпър функции
func add_to_local_scores(game_result: Dictionary):
	local_scores.append(game_result)

func translate_score_fields_in_array(scores_arr: Array) -> Array:
	var translated = []
	for s in scores_arr: translated.append(translate_score_fields(s))
	return translated

func translate_score_fields(score_dict: Dictionary) -> Dictionary:
	return {
		"score_id": score_dict.get("sid", ""),
		"score": score_dict.get("s", 0),
		"player_name": score_dict.get("pn", "Anonymous"),
		"metadata": score_dict.get("md", {}),
		"position": score_dict.get("position", 0),
		"timestamp": score_dict.get("t", 0)
	}

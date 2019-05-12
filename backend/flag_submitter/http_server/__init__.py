"""Flask server to submit flags"""

import os
import sys

BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, BASE_DIR)

import json

from flask import Flask, request, make_response

import storage
from helpers import exceptions

app = Flask(__name__)


def get_response(status_code, data=None, error=None):
    if error:
        return make_response({'error': error}, status_code)

    return make_response(json.dumps(data), status_code)


@app.route('/status')
def status():
    return 'OK'


@app.route('/submit')
def submit():
    team_token = request.headers.get('X-TeamToken')
    team_id = storage.teams.get_team_id_by_token(team_token)

    round = storage.game.get_current_round()

    if round == -1:
        return get_response(error='Game is not available yet', status_code=403)

    if not request.is_json or not isinstance(request.json.get('flags'), list):
        return get_response(error='Submit your flags as json in array with key "flags', status_code=400)

    responses = []
    for flag in request.json['flags']:
        flag = storage.flags.get_flag_by_str(flag_str=flag, round=round)

        try:
            storage.flags.check_flag(flag=flag, attacker=team_id, round=round)
        except exceptions.FlagSubmitException as e:
            responses.append(str(e))
        else:
            storage.flags.add_stolen_flag(flag=flag, attacker=team_id)
            attacker_delta = storage.teams.handle_attack(
                attacker_id=team_id,
                victim_id=flag.team_id,
                task_id=flag.task_id,
                round=round,
            )

            responses.append(f'Flag accepted! Earned {attacker_delta} flag points!')

    return get_response(status_code=200, data=responses)


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
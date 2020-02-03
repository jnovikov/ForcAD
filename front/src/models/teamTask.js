class TeamTask {
    constructor({
        id,
        task_id: taskId,
        team_id: teamId,
        status,
        stolen,
        lost,
        score,
        up_rounds: upRounds,
        round,
        message,
    }) {
        this.id = id;
        this.taskId = taskId;
        this.teamId = teamId;
        this.status = status;
        this.stolen = stolen;
        this.lost = lost;
        this.sla = (100.0 * upRounds) / Math.max(round, 1);
        this.score = score;
        this.message = message;
    }

    static comp(A, B) {
        return A.taskId - B.taskId;
    }
}

export default TeamTask;
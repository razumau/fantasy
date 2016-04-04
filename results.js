var users = [];

$.getJSON("https://popping-inferno-4625.firebaseio.com/users.json", function (list) {
	for (var key in list) {
		var user = list[key];
		if (user.remains < 100 && user.teams) {
			user.teams.sort(function (a, b) {
				return b.points - a.points;
			})
			var sum = 0;
			for (var i = user.teams.length - 1; i >= 0; i--) {
				sum += user.teams[i].points;
			};
			users.push({name: user.name, teams: user.teams, sum: sum});
		}
	}
	users.sort(function (a, b) {
		return b.sum - a.sum;
	});
	React.render(React.createElement(List, {users: users}), document.getElementById('center'));
});


var List = React.createClass({displayName: "List",
	render: function() {
		var users = [];
		for (var i = 0; i < this.props.users.length; i++) {
			this.props.users[i].place = i + 1;
			users.push(React.createElement(User, {user: this.props.users[i]}));
		};
		return (
			React.createElement("div", {className: "resultsList"}, 
				users
			)
		);
	}
	
});

var User = React.createClass({displayName: "User",
	render: function() {
		var teams = [];
		this.props.user.teams.forEach(function (team) {
			teams.push(React.createElement("p", null, team.name, " — ", team.points));
		});
		return (
			React.createElement("div", {className: "resultsUserTeams"}, 
				React.createElement("h3", null, 
							this.props.user.place, ". ", 
							this.props.user.name, " — ",
							this.props.user.sum
							), 
				teams
			)
		);
	}
});

function shuffle(o){
    for(var j, x, i = o.length; i; j = Math.floor(Math.random() * i), x = o[--i], o[i] = o[j], o[j] = x);
    return o;
};

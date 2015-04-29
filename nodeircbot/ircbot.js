function interval(func, wait, times){
    var interv = function(w, t){
        return function(){
            if(typeof t === "undefined" || t-- > 0){
                setTimeout(interv, w);
                try{
                    func.call(null);
                }
                catch(e){
                    t = 0;
                    throw e.toString();
                }
            }
        };
    }(wait, times);

    setTimeout(interv, wait);
};
// Create the configuration
var config = {
	channels: ["#codejungle"],
	server: "irc.freenode.net",
	botName: "DEABot"
};

// Get the lib
var irc = require("irc");

// Create the bot name
var bot = new irc.Client(config.server, config.botName, {
	channels: config.channels
});
function checkResponse(response, callback){
	if (response == "Yes"){
		callback();
	}
	else{
		soundTheAlarms();
		callback("Bot failed to respond");
	}

}
function pmBot (msg, callback){
	bot.say("SoberPenguin", msg);

	console.log("pmBot function called");

	var botResponse = "";
	bot.addListener('message', function(nick, to, text, message) {
		botResponse = text;
		checkResponse(text, function(err) {
			if(err){
				console.log("Bot failed to respond");
			}
			else{
				console.log("Everything is good!");
				callback(msg);
			}
		});
	});
	console.log(botResponse);
	console.log("Waiting 5 seconds for bots response");
	var now = new Date().getTime();
	while(new Date().getTime() < now + 5000) { }
	checkResponse(botResponse, function(err) {
			if(err){
				console.log("Bot failed to respond");
			}
			else{
				console.log("Everything is good!");
				callback(msg);
			}
		});
	console.log("Wait Complete");

}
function queryBot (){
	console.log("queryBot function called");
	pmBot("You Alive?", (function (msg) {
        setTimeout (queryBot, 10000); //queue for next ping in the next predefined interval
    }));
}

function soundTheAlarms(){

    interval(function(){
		bot.say("#codejungle", "FBIBot isn't responding to queries or has quit. Please alert HackPat/DrunkPat/C_C/WFeather for a restart");
	    bot.say("#codejungle", "Access code -----");
    }, 6000, 3);
}

bot.addListener('quit', function(nick, reason, channels, message) {
	if (nick == "FBIBot"){
		console.log("FBIBot has left the building");
	}
});
bot.addListener('part', function(channel, nick, reason, message) {
	if (nick == "FBIBot"){
		console.log("FBIBot has left the building");
	}
});
bot.addListener('registered', function(message) {
	console.log("Connected to " + config.server);
});
bot.addListener('motd', function(message) {
	console.log("MOTD Recieved");
});
bot.addListener('join', function(channel, nick, message) {
	console.log(nick + " Joined");
	if (nick == "DEABot"){
		console.log("DEABot matched");
		queryBot();
	}
});
// https://reaction.ppom.me/filters/ai-crawlers.html
local aiRobots = import "/var/lib/reaction/ai-robots.json";
local names = std.objectFields(aiRobots);

local joined = std.join("|", names);
local regex =  @'^<ip>.*"[^"]*(' + joined + ')[^"]*"$';

local actions = 'ACTIONS';

{
  streams: {
    nginx: {
      filters: {
        gptbot: {
          regex: [ regex ],
          actions: actions,
        }
      }
    }
  }
}


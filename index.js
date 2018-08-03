const express = require('express')
const app = express()

let runPy = new Promise(function(success, nosuccess) {

    const { spawn } = require('child_process');
    const pyprog = spawn('python', ['./trendFetcher.py']);

    pyprog.stdout.on('data', function(data) {

        success((data));
    });

    pyprog.stderr.on('data', (data) => {

        nosuccess(data);
    });
});

app.get('/', (req, res) => {

    runPy.then(function(fromRunpy) {
        res.end(fromRunpy);
    });
})

app.listen(4000, () => console.log('Application listening on port 4000!'))
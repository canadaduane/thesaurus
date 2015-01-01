/** @jsx React.DOM */

var App = React.createClass({
  getInitialState: function() {
    return {
      "results": [],
      "loading": false,
      "query": null,
      "querySize": 100
    }
  },

  handleSubmit: function(words) {
    this.setState({"loading": true})
  },

  handleError: function(words, errMsg) {
    this.setState({"loading": false})
  },

  handleResults: function(data) {
    this.setState({"results": data, "loading": false})
  },

  handleMore: function(e) {
    var newN = this.state.querySize + 100
    this.setState({"querySize": newN})
  },

  handleQuery: function(words) {
    this.setState({"query": words, "loading": true})
  },

  resultsShouldBeHidden: function() {
    return this.state.results.length == 0 || this.state.loading
  },

  render: function() {
    var spinnerClass = React.addons.classSet({
      "spinner": true,
      "hidden": !this.state.loading
    })

    var moreClass = React.addons.classSet({
      "hidden": this.state.results.length == 0
    })

    return (
      <div className="row">
        <div className="offset-by-one-third one-third column">
          <WordSearch
            url={this.props.lookupUrl}
            query={this.state.query}
            querySize={this.state.querySize}
            onResults={this.handleResults}
            onError={this.handleError}
            onSubmit={this.handleSubmit}
          />
          <ResultTable
            data={this.state.results}
            hidden={this.resultsShouldBeHidden()}
            onQuery={this.handleQuery}
          />
          <div className={spinnerClass}>Loading...</div>
          <div className={moreClass}>
            <button onClick={this.handleMore}>More...</button>
          </div>
        </div>
      </div>
    )
  }
})

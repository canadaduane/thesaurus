/** @jsx React.DOM */

var App = React.createClass({displayName: 'App',
  getInitialState: function() {
    return {
      "results": [],
      "loading": false
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
    var newN = this.state.n + 100
    this.setState({"n": newN})
  },

  handleQuery: function(words) {
    this.setState({"query": words})
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
      React.DOM.div({className: "row"}, 
        React.DOM.div({className: "offset-by-one-third one-third column"}, 
          WordSearch({url: this.props.lookupUrl, 
            query: this.state.query, 
            onResults: this.handleResults, 
            onError: this.handleError, 
            onSubmit: this.handleSubmit}
          ), 
          ResultTable({data: this.state.results, 
            hidden: this.resultsShouldBeHidden(), 
            onQuery: this.handleQuery}
          ), 
          React.DOM.div({className: spinnerClass}, "Loading..."), 
          React.DOM.div({className: moreClass}, 
            React.DOM.button({onClick: this.handleMore}, "More...")
          )
        )
      )
    )
  }
})

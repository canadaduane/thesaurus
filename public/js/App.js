/** @jsx React.DOM */

var App = React.createClass({displayName: 'App',
  getInitialState: function() {
    return {
      "results": [],
      "n": 30,
      "words": null,
      "loading": false
    }
  },

  handleSubmit: function(words) {
    console.log("handleSubmit", "setting words to", words, " and loading to true")
    this.setState({"words": words, "loading": true})
  },

  handleError: function(words, errMsg) {
    this.setState({"loading": false})
  },

  handleResults: function(data) {
    console.log("handleResults", "setting results", " and loading to false")
    this.setState({"results": data, "loading": false})
  },

  handleMore: function(e) {
    var newN = this.state.n + 30
    this.setState({"n": newN})
  },

  hiddenResults: function() {
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
            n: this.state.n, 
            words: this.state.words, 
            onResults: this.handleResults, 
            onError: this.handleError, 
            onSubmit: this.handleSubmit}
          ), 
          ResultTable({data: this.state.results, 
            hidden: this.hiddenResults(), 
            onQuery: this.handleSubmit}
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

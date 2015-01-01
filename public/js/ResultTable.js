/** @jsx React.DOM */

var ResultTable = React.createClass({displayName: 'ResultTable',
  render: function() {
    var tableClass = React.addons.classSet({
      "hidden": this.props.hidden
    })

    return (
      React.DOM.div({className: tableClass}, 
        React.DOM.div({className: "row"}, 
          React.DOM.div({className: "two-thirds column heading"}, "Word"), 
          React.DOM.div({className: "one-third column heading"}, "Nearest")
        ), 
        this.props.data.map(function(row) {
          return (
          React.DOM.div({className: "row"}, 
            React.DOM.div({className: "two-thirds column"}, 
              React.DOM.a({href: "#", onClick: function(){ this.props.onQuery(row[0]) }.bind(this)}, row[0])
            ), 
            React.DOM.div({className: "one-third column"}, 
              row[1].toFixed(3)
            )
          )
          )
        }.bind(this))
      )
    )
  }
})

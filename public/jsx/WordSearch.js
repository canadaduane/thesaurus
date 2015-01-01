/** @jsx React.DOM */

var WordSearch = React.createClass({
  getInitialState: function() {
    return {"showMessage": false, "words": null, "n": 30}
  },

  componentWillReceiveProps: function(nextProps) {
    // var words = this.props.words,
    //     n     = this.props.n

    // console.log("componentWillReceiveProps", words, nextProps.words, nextProps.n)
    // var changed = false;
    if (this.props.query != nextProps.query) {
      this.setState({"words": nextProps.query})
    }

    // if (words != nextProps.words) { changed = true; words = nextProps.words }
    // if (n     != nextProps.n)     { changed = true; n     = nextProps.n }
  },

  componentWillUpdate: function(nextProps, nextState) {
    if (this.state.words != nextState.words || this.state.n != nextState.n) {
      this.lookupWords(nextState.words, nextState.n)
    }
  },

  showMessage: function(msg) {
    var msgEl = this.refs.message.getDOMNode(), me = this
    $(msgEl).html(msg)
    this.setState({"showMessage": true})
    setTimeout(function(){ me.setState({"showMessage": false}) }, 5000)
  },

  getWords: function() {
    return this.refs.words.getDOMNode().value.trim()
  },

  lookupWords: function(words, n) {
    var handleSuccess = function(data) {
      if (this.props.onResults) {
        this.props.onResults(data)
      }
    }.bind(this)

    var handleError = function(errMsg) {
      this.showMessage(errMsg)
      console.error(words, errMsg)
      if (this.props.onError) {
        this.props.onError(words, errMsg)
      }
    }.bind(this)

    $.ajax({
      url: this.props.url,
      data: { words: words, n: n },
      dataType: "json",
      success: function(data) {
        if (data.error) {
          handleError(data.error)
        } else {
          handleSuccess(data)
        }
      },
      error: function(xhr, status, err) {
        handleError(err.toString())
      }
    });
  },

  handleSubmit: function(e) {
    e.preventDefault()

    var words = this.getWords()
    this.setState({ "words": words })

    if (this.props.onSubmit) {
      this.props.onSubmit(words)
    }
    console.log("WordSearch#handleSubmit", words)
    // this.lookupWords(words, this.props.n)
  },

  render: function() {
    var msgClass = React.addons.classSet({
      "error": true,
      "message": true,
      "hidden": !this.state.showMessage
    })
    return (
      <div>
        <form className="wordsearch" onSubmit={this.handleSubmit}>
          <div><label for="words">Lookup Word(s):</label></div>
          <input type="text" id="words" ref="words" placeholder="words, to, lookup" />
          <input type="submit" className="button-primary" value="Lookup" />
        </form>
        <div className={msgClass} ref="message" />
      </div>
    );
  }
});
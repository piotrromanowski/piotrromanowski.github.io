---
title: "[Archive] React unit testing"
date: 2018-02-17T16:22:41-04:00
draft: false
---

Testing, A topic that doesn't have nearly as many tutorials, videos, and blog
posts as it should have. Specifically, how to unit test components in React.

First, let's look at how Wikipedia defines "unit testing".

> In computer programming, unit testing is a software testing method by which
> individual units of source code, sets of one or more computer program modules
> together with associated control data, usage procedures, and operating
> procedures, are tested to determine whether they are fit for use.

Now, let's take a look at what enzyme's docs have to say about shallow rendering

> Shallow rendering is useful to constrain yourself to testing a component as a
> unit, and to ensure that your tests aren't indirectly asserting on behavior
> of child components.

It's safe to say that enzymes shallow rendering is the right tool when you're
trying to unit test your components.

Shallow rendering constrains developers to only make assertions on a components
props, and the props of it's immediate children. Although shallow rendering
permits you to access a components state, we should try to avoid doing
so because we shouldn't be testing the implementation details of the component.
Shallow rendering will also help improve the performance of your tests since it
doesn't require all the extra DOM setup.

Alright, I could continue writing about unit testing react components, or, I could
bring in an example. Let's take a look at the below EnhancedButton component.

```jsx {style=gruvbox}
    // ... other imports ...
    import {Button} from './Button'
    import {Error} from './Error'

    export interface EnhancedButtonProps {
        errorText?: string
        onClick: () => void
    }

    export interface State {
        count: number
        touched: boolean
    }

    export class EnhancedButton
    extends React.Component<EnhancedButtonProps, State> {

        constructor(props: EnhancedButtonProps) {
        super(props)

            this.state = {
              count: 0,
              touched: false,
            }

        }

        private onClick = () => {
            this.setState({touched: true, count: this.state.count + 1})
            this.props.onClick()
        }

        render() {
            const error = !!this.props.errorText
                ? <Error>{this.props.errorText}</Error>
                : undefined
            const name = this.state.touched
                ? ('Clicked ' + this.state.count + ' time(s)!')
                : 'Click Me'
            return (
                <span>
                  <Button
                    errored={!!this.props.errorText}
                    onClick={this.onClick}
                  >
                    {name}
                  </Button>
                  {error}
                </span>
            )
        }
    }
```

Now after looking at that component, let's think about what's important to test.
I like to make a list of guarantees that the component is making to the consumer.

### Without errorText

- We can say that we expect this component to render a mysterious "Button"
  component with a particular set of props. We don't care what that "Button" does
  with the props, we just want them to be passed through.
- We expect that it does not initially render an Error component
- When the mysterious "Button" is clicked, we expect the onClick prop to be
  invoked and to change the children of the component

### With errorText

- We expect that it renders an Error component

Here's what these expectations would look like in code:

```jsx {style=gruvbox}
describe('EnhancedButton', () => {
    let props: Readonly<EnhancedButtonProps>
    let component: ShallowWrapper<any, any>

    beforeEach(() => {
        props = {
            onClick: spy(),
        }
    })

    context('when rendered without errorText', () => {

        beforeEach(() => {
          component = shallow(<EnhancedButton {...props} />)
        })

        it('should render a Button', () => {
          // Notice that I'm not digging into the components
          // implementation and only asserting that props
          // are properly being passed through to it
          expect(component.find(Button).props().children)
            .to.equal('Click Me')
          expect(component.find(Button).props().errored).to.be.false
        })

        it('should not render error div', () => {
          expect(component.find(Error)).to.have.length(0)
        })

        context('and the Button is clicked', () => {

          beforeEach(() => {
            component.find(Button).simulate('click')
          })

          it('should invoke onClick prop', () => {
            // Continued testing that the onClick handler
            // is being passed through to the Button
            expect((props.onClick as SinonSpy).callCount).to.equal(1)
          })

          it('should render with clicked count', () => {
            // We don't care how the Button renders the children,
            // we just want to make sure that it's receiving them.
            // Also notice that we're implicitly testing that the
            // state of our EnhancedButton is being updated properly.
            expect(component.find(Button).props().children)
              .to.equal('Clicked 1 time(s)!')
          })
        })

    })

    context('when rendered with errorText', () => {

        beforeEach(() => {
          props = {...props, errorText: 'Something went wrong'}
          component = shallow(<EnhancedButton {...props} />)
        })

        it('should not render error div', () => {
          expect(component.find(Error)).to.have.length(1)
          // Again, we aren't concerned with the implementation of
          // the `Error` component, just that it's passed the
          // correct props.
          expect(component.find(Error).props().children)
            .to.equal(props.errorText)
        })

    })
})
```

And that's how I test 90% of my components! Of course, there are more complicated
scenarios when you're dealing with larger nesting, HOCs, or third party libraries,
but this style of testing has been pretty reliable.

Follow me on twitter [@nullpiotr](http://www.twitter.com/nullpiotr) for regular updates
on future blog posts! :)

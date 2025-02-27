import React, {
  useState,
  useEffect,
  useRef,
  forwardRef,
  createRef,
} from 'react'
import { GraphicalIcon, ProminentLink } from '../common'
import { useChart } from './contributions-summary/use-chart'
import { TotalReputation } from './contributions-summary/TotalReputation'
import { CategorySummary } from './contributions-summary/CategorySummary'
import { TrackSwitcher } from './contributions-summary/TrackSwitcher'

const leftMargin = 100
const topMargin = 150
const buffer = 8

export type CategoryId =
  | 'publishing'
  | 'mentoring'
  | 'authoring'
  | 'building'
  | 'maintaining'
  | 'other'

export type Category = {
  id: CategoryId
  reputation: number
  metricFull?: string
  metricShort?: string
}

export type Track = {
  id: string
  title: string
  iconUrl: string
  categories: readonly Category[]
}

type Links = {
  contributions: string
}

export const CATEGORY_TITLES = {
  publishing: 'Publishing',
  mentoring: 'Mentoring',
  authoring: 'Authoring',
  building: 'Building',
  maintaining: 'Maintaining',
  other: 'Other',
}

export const CATEGORY_ICONS = {
  publishing: 'community-solutions',
  mentoring: 'mentoring',
  authoring: 'authoring',
  building: 'building',
  maintaining: 'maintaining',
  other: 'more-horizontal',
}

export const getTotalReputation = (track: Track): number => {
  return track.categories.reduce(
    (sum, category) => sum + category.reputation,
    0
  )
}

export const ContributionsSummary = ({
  tracks,
  handle,
  links,
}: {
  tracks: readonly Track[]
  handle: string
  links: Links
}): JSX.Element => {
  const allTrack = tracks.find((track) => track.id === 'all')

  if (!allTrack) {
    throw new Error('No data found for all track')
  }
  const [canvas, setCanvas] = useState<HTMLCanvasElement | null>(null)
  const [currentTrack, setCurentTrack] = useState(tracks[0])
  const labelRefs = useRef(
    currentTrack.categories.map(() => createRef<HTMLDivElement>())
  )
  const trackColor =
    currentTrack.id !== 'all'
      ? getComputedStyle(document.documentElement).getPropertyValue(
          `--track-color-${currentTrack.id}`
        )
      : undefined

  const { chart } = useChart(
    canvas,
    currentTrack.categories.map((category) => category.reputation),
    trackColor
  )

  useEffect(() => {
    if (!canvas || !chart) {
      return
    }
    const timeout = setTimeout(() => {
      const containerHeight = (canvas.parentNode as HTMLElement).offsetHeight

      const point0 = chart.getDatasetMeta(0).iScale.getPointLabelPosition(0)
      const label0 = labelRefs.current[0].current
      if (!label0) {
        return
      }
      label0.style.left = `${point0.left + leftMargin}px`
      label0.style.marginLeft = `${-(label0.offsetWidth / 2)}px`
      label0.style.bottom = `${containerHeight - point0.bottom + topMargin}px`
      label0.style.visibility = 'visible'

      const point1 = chart.getDatasetMeta(0).iScale.getPointLabelPosition(1)
      const label1 = labelRefs.current[1].current
      if (!label1) {
        return
      }
      label1.style.left = `${point1.left + leftMargin + buffer}px`
      label1.style.bottom = `${
        containerHeight - point1.bottom + topMargin - label1.offsetHeight / 2
      }px`
      label1.style.visibility = 'visible'

      const point2 = chart.getDatasetMeta(0).iScale.getPointLabelPosition(2)
      const label2 = labelRefs.current[2].current
      if (!label2) {
        return
      }
      label2.style.left = `${point2.left + leftMargin + buffer}px`
      label2.style.bottom = `${
        containerHeight - point2.bottom + topMargin - label2.offsetHeight / 2
      }px`
      label2.style.visibility = 'visible'

      const point3 = chart.getDatasetMeta(0).iScale.getPointLabelPosition(3)
      const label3 = labelRefs.current[3].current
      if (!label3) {
        return
      }
      label3.style.left = `${point3.left + leftMargin}px`
      label3.style.marginLeft = `${-(label3.offsetWidth / 2)}px`
      label3.style.bottom = `${
        containerHeight - point3.bottom + topMargin - label3.offsetHeight
      }px`
      label3.style.visibility = 'visible'

      const point4 = chart.getDatasetMeta(0).iScale.getPointLabelPosition(4)
      const label4 = labelRefs.current[4].current
      if (!label4) {
        return
      }
      label4.style.left = `${
        point4.left + leftMargin - label4.offsetWidth - buffer
      }px`
      label4.style.bottom = `${
        containerHeight - point4.bottom + topMargin - label4.offsetHeight / 2
      }px`
      label4.style.visibility = 'visible'

      const point5 = chart.getDatasetMeta(0).iScale.getPointLabelPosition(5)
      const label5 = labelRefs.current[5].current
      if (!label5) {
        return
      }
      label5.style.left = `${
        point5.left + leftMargin - label5.offsetWidth - buffer
      }px`
      label5.style.bottom = `${
        containerHeight - point5.bottom + topMargin - label5.offsetHeight / 2
      }px`
      label5.style.visibility = 'visible'
    }, 250)

    return () => clearTimeout(timeout)
  }, [canvas, chart])

  return (
    <section className="contributions-section">
      <div className="lg-container container">
        <div className="summary">
          <header className="section-header">
            <GraphicalIcon icon="contribute" hex={true} />
            <h2>Contributions</h2>
          </header>
          <TotalReputation
            handle={handle}
            reputation={getTotalReputation(allTrack)}
          />
          <TrackSwitcher
            tracks={tracks}
            value={currentTrack}
            setValue={setCurentTrack}
          />

          {currentTrack.categories.map((category) => (
            <CategorySummary key={category.id} category={category} />
          ))}

          <ProminentLink
            link={links.contributions}
            text={`See ${handle}'s contributions`}
          />
        </div>

        <div className="chart-container">
          {currentTrack.categories.map((category, i) => {
            return (
              <CategoryLabel
                key={category.id}
                ref={labelRefs.current[i]}
                category={category}
              />
            )
          })}
          <div className="chart">
            <canvas id="contributions-chart" ref={setCanvas} />
          </div>
        </div>
      </div>
    </section>
  )
}

const CategoryLabel = forwardRef<HTMLDivElement, { category: Category }>(
  ({ category }, ref) => {
    return (
      <div className="label" ref={ref}>
        <GraphicalIcon icon={CATEGORY_ICONS[category.id]} hex />
        <div className="title">{CATEGORY_TITLES[category.id]}</div>
        {category.metricShort ? (
          <div className="subtitle">{category.metricShort}</div>
        ) : null}
      </div>
    )
  }
)
CategoryLabel.displayName = 'CategoryLabel'
